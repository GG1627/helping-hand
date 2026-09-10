import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_packet.dart';

class BleConnectionService extends ChangeNotifier {
  BleConnectionService() {
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      _notify();
    });
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      _notify();
    });
  }

  static const String targetDeviceName = 'HelpingHand-Glove';
  static final Guid serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid notifyUuid = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');

  final StreamController<BlePacket> _packetController =
      StreamController<BlePacket>.broadcast(sync: true);
  final List<ScanResult> _scanResults = [];
  final Queue<DateTime> _recentValidPackets = Queue<DateTime>();
  final Set<String> _intentionalDisconnects = <String>{};

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? _connectedDevice;
  BlePacket? _lastPacket;
  bool _isScanning = false;
  bool _scanRequestInFlight = false;
  bool _autoConnectEnabled = true;
  bool _autoConnectInProgress = false;
  bool _disposed = false;
  String _status = 'Idle';
  int _targetFoundCount = 0;
  int _packetCount = 0;
  double _imuRoll = 0;
  bool _imuRollInitialized = false;

  BluetoothAdapterState get adapterState => _adapterState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  BlePacket? get lastPacket => _lastPacket;
  Stream<BlePacket> get packets => _packetController.stream;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;
  String get status => _status;
  int get targetFoundCount => _targetFoundCount;
  int get packetCount => _packetCount;
  double get imuRoll => _imuRoll;

  bool get autoConnectEnabled => _autoConnectEnabled;
  set autoConnectEnabled(bool value) {
    if (_autoConnectEnabled == value) return;
    _autoConnectEnabled = value;
    _notify();
  }

  String get connectedDeviceName {
    final device = _connectedDevice;
    return device == null ? 'Not connected' : deviceName(device);
  }

  double get observedSampleRateHz {
    _pruneRecentPackets(DateTime.now().toUtc());
    if (_recentValidPackets.length < 2) return 0;
    final elapsedUs = _recentValidPackets.last
        .difference(_recentValidPackets.first)
        .inMicroseconds;
    if (elapsedUs <= 0) return 0;
    return (_recentValidPackets.length - 1) * 1000000 / elapsedUs;
  }

  bool hasFreshValidPacket({Duration maximumAge = const Duration(seconds: 2)}) {
    final packet = _lastPacket;
    return packet != null &&
        packet.isValid &&
        DateTime.now().toUtc().difference(packet.receivedAt) <= maximumAge;
  }

  String deviceName(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    return platformName.isNotEmpty ? platformName : device.remoteId.str;
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    final hasScan = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final hasConnect =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    if (!(hasScan && hasConnect)) {
      _setStatus('Missing BLE permissions (Nearby Devices).');
      return false;
    }
    return true;
  }

  Future<void> startScan() async {
    if (_scanRequestInFlight || _disposed) return;
    _scanRequestInFlight = true;
    if (_adapterState != BluetoothAdapterState.on) {
      _setStatus('Bluetooth is OFF. Turn it on first.');
      _scanRequestInFlight = false;
      return;
    }
    if (!await _ensurePermissions()) {
      _scanRequestInFlight = false;
      return;
    }

    await _scanSub?.cancel();
    _scanResults.clear();
    _targetFoundCount = 0;
    _setStatus('Scanning...');
    _scanSub = FlutterBluePlus.onScanResults.listen(
      _handleScanResults,
      onError: (Object error, StackTrace stackTrace) {
        _setStatus('Scan stream error: $error');
      },
    );

    var scanStarted = false;
    try {
      await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );
      scanStarted = true;
    } catch (error) {
      final needsFineLocation = error.toString().toLowerCase().contains(
        'access fine location required',
      );
      if (needsFineLocation) {
        final status = await Permission.locationWhenInUse.request();
        if (status.isGranted) {
          try {
            await FlutterBluePlus.startScan(
              withServices: [serviceUuid],
              androidScanMode: AndroidScanMode.lowLatency,
              androidUsesFineLocation: true,
              androidCheckLocationServices: false,
            );
            scanStarted = true;
          } catch (fallbackError) {
            debugPrint('[BLE_SERVICE] fallback scan failed: $fallbackError');
          }
        }
      }
    }
    _scanRequestInFlight = false;
    if (!scanStarted) {
      _setStatus(
        'Scan failed. Check Nearby Devices (and Location on older Android).',
      );
      return;
    }
    _setStatus('Scanning for $targetDeviceName...');
  }

  void _handleScanResults(List<ScanResult> results) {
    BluetoothDevice? candidate;
    for (final result in results) {
      if (!_isTargetResult(result)) continue;
      final index = _scanResults.indexWhere(
        (item) => item.device.remoteId == result.device.remoteId,
      );
      if (index == -1) {
        _scanResults.add(result);
      } else {
        _scanResults[index] = result;
      }
      _targetFoundCount += 1;
      candidate ??= result.device;
    }
    _notify();
    if (_autoConnectEnabled &&
        !_autoConnectInProgress &&
        _connectedDevice == null &&
        candidate != null) {
      _autoConnectInProgress = true;
      _setStatus('Target found. Auto-connecting...');
      unawaited(
        connect(candidate).whenComplete(() {
          _autoConnectInProgress = false;
        }),
      );
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _setStatus('Scan stopped');
    } catch (error) {
      _setStatus('Could not stop scan: $error');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (_connectedDevice?.remoteId == device.remoteId) {
      _setStatus('Already connected to ${deviceName(device)}');
      return;
    }
    await stopScan();
    await disconnect();
    _setStatus('Connecting to ${deviceName(device)}...');

    try {
      await device.connect(timeout: const Duration(seconds: 12));
    } catch (error) {
      if (!error.toString().toLowerCase().contains('already')) {
        _setStatus('Connect failed: $error');
        return;
      }
    }

    await _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      if (state != BluetoothConnectionState.disconnected) return;
      final intentional = _intentionalDisconnects.remove(device.remoteId.str);
      _connectedDevice = null;
      unawaited(_notifySub?.cancel());
      _notifySub = null;
      _setStatus(
        _autoConnectEnabled && !intentional
            ? 'Disconnected. Auto-reconnecting...'
            : 'Disconnected',
      );
      if (_autoConnectEnabled && !intentional) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            if (!_disposed) return startScan();
          }),
        );
      }
    });

    try {
      await device.requestMtu(512);
    } catch (error) {
      debugPrint('[BLE_SERVICE] MTU request unavailable: $error');
    }

    _connectedDevice = device;
    _notify();
    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } catch (error) {
      _setStatus('Connected, but service discovery failed: $error');
      return;
    }
    BluetoothCharacteristic? notifyCharacteristic;
    for (final service in services) {
      if (service.uuid != serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == notifyUuid) {
          notifyCharacteristic = characteristic;
        }
      }
    }
    if (notifyCharacteristic == null) {
      _setStatus('Connected, but notify characteristic not found.');
      return;
    }

    try {
      await notifyCharacteristic.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = notifyCharacteristic.lastValueStream.listen(
        _handleNotification,
        onError: (Object error, StackTrace stackTrace) {
          _setStatus('Notification stream error: $error');
        },
      );
    } catch (error) {
      _setStatus('Connected, but notifications could not be enabled: $error');
      return;
    }
    _connectedDevice = device;
    _setStatus('Connected and listening');
  }

  void _handleNotification(List<int> bytes) {
    if (bytes.isEmpty || _disposed) return;
    final raw = utf8.decode(bytes, allowMalformed: true);
    if (raw.trim().isEmpty) return;
    final packet = BlePacket.parse(raw, receivedAt: DateTime.now().toUtc());
    _lastPacket = packet;
    _packetCount += 1;
    if (packet.isValid) {
      _recentValidPackets.add(packet.receivedAt);
      _pruneRecentPackets(packet.receivedAt);
    }
    if (packet.ay != null && packet.az != null) {
      const alpha = 0.18;
      final accelRoll = math.atan2(packet.ay!, packet.az!);
      _imuRoll = _imuRollInitialized
          ? (_imuRoll * (1 - alpha)) + (accelRoll * alpha)
          : accelRoll;
      _imuRollInitialized = true;
      _imuRoll = _imuRoll.clamp(-0.5, 0.5).toDouble();
    }
    _packetController.add(packet);
    _notify();
  }

  Future<void> disconnect() async {
    final device = _connectedDevice;
    _connectedDevice = null;
    await _notifySub?.cancel();
    _notifySub = null;
    if (device != null) {
      _intentionalDisconnects.add(device.remoteId.str);
      try {
        await device.disconnect();
      } catch (error) {
        _intentionalDisconnects.remove(device.remoteId.str);
        debugPrint('[BLE_SERVICE] disconnect failed: $error');
      }
    }
    _notify();
  }

  bool _isTargetResult(ScanResult result) {
    final target = targetDeviceName.toLowerCase();
    final advertisementName = result.advertisementData.advName
        .trim()
        .toLowerCase();
    final platformName = result.device.platformName.trim().toLowerCase();
    return advertisementName == target ||
        platformName == target ||
        result.advertisementData.serviceUuids.contains(serviceUuid);
  }

  void _pruneRecentPackets(DateTime now) {
    final cutoff = now.subtract(const Duration(seconds: 5));
    while (_recentValidPackets.isNotEmpty &&
        _recentValidPackets.first.isBefore(cutoff)) {
      _recentValidPackets.removeFirst();
    }
  }

  void _setStatus(String value) {
    _status = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(FlutterBluePlus.stopScan());
    unawaited(_adapterSub?.cancel());
    unawaited(_scanSub?.cancel());
    unawaited(_isScanningSub?.cancel());
    unawaited(_connectionSub?.cancel());
    unawaited(_notifySub?.cancel());
    unawaited(_connectedDevice?.disconnect());
    unawaited(_packetController.close());
    super.dispose();
  }
}
