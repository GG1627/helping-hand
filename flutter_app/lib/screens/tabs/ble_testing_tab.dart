import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/warm_components.dart';

class BleTestingTab extends StatefulWidget {
  const BleTestingTab({super.key});

  @override
  State<BleTestingTab> createState() => _BleTestingTabState();
}

class _BleTestingTabState extends State<BleTestingTab> {
  // ESP32 BLE UART defaults (Nordic UART profile). Replace these if your ESP32 uses custom UUIDs.
  static final Guid _serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid _notifyUuid = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid _writeUuid = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  final TextEditingController _txController = TextEditingController(text: 'ping');
  final List<ScanResult> _scanResults = [];
  final List<String> _logs = [];
  final List<String> _debugLogs = [];

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  bool _isScanning = false;
  bool _scanRequestInFlight = false;
  String _status = 'Idle';
  String _imuWhoAmI = '--';
  double? _ax;
  double? _ay;
  double? _az;
  double? _gx;
  double? _gy;
  double? _gz;
  DateTime? _lastImuUpdate;
  int _imuPacketCount = 0;

  @override
  void initState() {
    super.initState();
    _debug('BLE tab initialized');
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      setState(() {
        _adapterState = state;
      });
      _debug('Adapter state: ${state.name}');
    });
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() {
        _isScanning = scanning;
      });
      _debug('isScanning stream: $scanning');
    });
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _connectionSub?.cancel();
    _notifySub?.cancel();
    _txController.dispose();
    unawaited(_disconnectCurrent());
    super.dispose();
  }

  void _debug(String message) {
    if (!mounted) return;
    final line = '${DateTime.now().toIso8601String()}  $message';
    setState(() {
      _debugLogs.insert(0, line);
      if (_debugLogs.length > 60) {
        _debugLogs.removeRange(60, _debugLogs.length);
      }
    });
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    _debug(
      'Permissions scan=${statuses[Permission.bluetoothScan]} connect=${statuses[Permission.bluetoothConnect]} location=${statuses[Permission.locationWhenInUse]}',
    );

    final hasScan = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final hasConnect = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final hasLocation = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (!(hasScan && hasConnect && hasLocation)) {
      _setStatus('Missing BLE permissions (Nearby Devices/Location).');
      return false;
    }
    return true;
  }

  Future<void> _startScan() async {
    if (_scanRequestInFlight) {
      _debug('Scan ignored: request already in flight');
      return;
    }
    _scanRequestInFlight = true;

    if (_adapterState != BluetoothAdapterState.on) {
      _setStatus('Bluetooth is OFF. Turn it on first.');
      _debug('Scan blocked: adapter not ON');
      _scanRequestInFlight = false;
      return;
    }
    if (!await _ensurePermissions()) {
      _scanRequestInFlight = false;
      return;
    }

    _scanSub?.cancel();
    _scanResults.clear();
    _setStatus('Scanning...');
    _debug('Starting scan...');
    setState(() {
      _isScanning = true;
    });

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        for (final result in results) {
          final index = _scanResults.indexWhere(
            (item) => item.device.remoteId == result.device.remoteId,
          );
          if (index == -1) {
            _scanResults.add(result);
          } else {
            _scanResults[index] = result;
          }
        }
      });
      _debug('Scan callback: ${results.length} raw, ${_scanResults.length} unique');
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
      _debug('startScan returned (timeout or stop)');
    } catch (e) {
      _setStatus('Scan failed: $e');
      _debug('Scan failed: $e');
      setState(() {
        _isScanning = false;
      });
      _scanRequestInFlight = false;
      return;
    }

    _scanRequestInFlight = false;
    _setStatus('Scanning window started');
  }

  Future<void> _stopScan() async {
    _debug('Stopping scan');
    await FlutterBluePlus.stopScan();
    _setStatus('Scan stopped');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    await _disconnectCurrent();

    _setStatus('Connecting to ${_deviceName(device)}...');
    _debug('Connecting to ${_deviceName(device)} (${device.remoteId.str})');

    try {
      await device.connect(timeout: const Duration(seconds: 12));
    } catch (e) {
      // Device may already be connected from a prior session; otherwise surface the error.
      if (!e.toString().toLowerCase().contains('already')) {
        _setStatus('Connect failed: $e');
        _debug('Connect failed: $e');
        return;
      }
    }

    _connectionSub = device.connectionState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          _connectedDevice = null;
          _notifyCharacteristic = null;
          _writeCharacteristic = null;
        });
        _debug('Device disconnected');
      }
    });

    final services = await device.discoverServices();
    BluetoothCharacteristic? notify;
    BluetoothCharacteristic? write;

    for (final service in services) {
      if (service.uuid != _serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _notifyUuid) notify = characteristic;
        if (characteristic.uuid == _writeUuid) write = characteristic;
      }
    }

    if (notify == null) {
      _setStatus('Connected, but notify characteristic not found.');
      _debug('Connected but notify characteristic missing');
      return;
    }

    // Look out: ESP32 must call `notify()` after value updates, or the app will connect but never receive data.
    await notify.setNotifyValue(true);
    _notifySub?.cancel();
    _notifySub = notify.lastValueStream.listen((bytes) {
      if (bytes.isEmpty || !mounted) return;
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      if (text.isEmpty) return;
      setState(() {
        _tryUpdateImuFromPacket(text);
        _logs.insert(0, '${DateTime.now().toIso8601String()}  $text');
      });
    });

    if (!mounted) return;
    setState(() {
      _connectedDevice = device;
      _notifyCharacteristic = notify;
      _writeCharacteristic = write;
    });
    _setStatus('Connected and listening');
    _debug('Connected + notify subscribed');
  }

  Future<void> _sendData() async {
    final write = _writeCharacteristic;
    if (write == null) {
      _setStatus('Write characteristic not available.');
      return;
    }

    final payload = _txController.text.trim();
    if (payload.isEmpty) {
      _setStatus('Enter a message before sending.');
      return;
    }

    // Look out: If your ESP32 firmware expects newline-delimited messages, append '\n' before write.
    await write.write(utf8.encode(payload), withoutResponse: write.properties.writeWithoutResponse);
    _setStatus('Sent: $payload');
  }

  Future<void> _disconnectCurrent() async {
    final device = _connectedDevice;
    if (device == null) return;
    try {
      await device.disconnect();
      _debug('Disconnected from ${device.remoteId.str}');
    } catch (e) {
      _debug('Disconnect error: $e');
    }
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() {
      _status = message;
    });
  }

  String _deviceName(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;
    return device.remoteId.str;
  }

  void _tryUpdateImuFromPacket(String packet) {
    final segments = packet.split(',');
    final parsed = <String, String>{};
    for (final segment in segments) {
      final parts = segment.split('=');
      if (parts.length != 2) continue;
      parsed[parts[0].trim()] = parts[1].trim();
    }

    if (!parsed.containsKey('ax') || !parsed.containsKey('gx')) return;

    final ax = double.tryParse(parsed['ax'] ?? '');
    final ay = double.tryParse(parsed['ay'] ?? '');
    final az = double.tryParse(parsed['az'] ?? '');
    final gx = double.tryParse(parsed['gx'] ?? '');
    final gy = double.tryParse(parsed['gy'] ?? '');
    final gz = double.tryParse(parsed['gz'] ?? '');

    if (ax == null || ay == null || az == null || gx == null || gy == null || gz == null) {
      return;
    }

    _imuWhoAmI = parsed['who'] ?? _imuWhoAmI;
    _ax = ax;
    _ay = ay;
    _az = az;
    _gx = gx;
    _gy = gy;
    _gz = gz;
    _imuPacketCount += 1;
    _lastImuUpdate = DateTime.now();
  }

  String _fmt3(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(3);
  }

  String _lastUpdateText() {
    final last = _lastImuUpdate;
    if (last == null) return 'No packets parsed yet';
    final seconds = DateTime.now().difference(last).inSeconds;
    if (seconds <= 0) return 'Updated just now';
    return 'Updated ${seconds}s ago';
  }

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'BLE Testing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BLE Status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Adapter: ${_adapterState.name} | ${_connectedDevice == null ? 'Not connected' : 'Connected'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _isScanning ? _stopScan : _startScan,
                      child: Text(_isScanning ? 'Stop Scan' : 'Start Scan'),
                    ),
                    if (_connectedDevice != null)
                      OutlinedButton(
                        onPressed: _disconnectCurrent,
                        child: const Text('Disconnect'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live IMU Values', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'WHO_AM_I: $_imuWhoAmI  |  Packets: $_imuPacketCount  |  ${_lastUpdateText()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ImuMetricTile(label: 'Accel X (g)', value: _fmt3(_ax)),
                    _ImuMetricTile(label: 'Accel Y (g)', value: _fmt3(_ay)),
                    _ImuMetricTile(label: 'Accel Z (g)', value: _fmt3(_az)),
                    _ImuMetricTile(label: 'Gyro X (dps)', value: _fmt3(_gx)),
                    _ImuMetricTile(label: 'Gyro Y (dps)', value: _fmt3(_gy)),
                    _ImuMetricTile(label: 'Gyro Z (dps)', value: _fmt3(_gz)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BLE Debug', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'scanInFlight=$_scanRequestInFlight | isScanning=$_isScanning | results=${_scanResults.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                if (_debugLogs.isEmpty)
                  Text(
                    'No debug events yet.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (_debugLogs.isNotEmpty)
                  ..._debugLogs.take(8).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line, style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discovered Devices', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_scanResults.isEmpty)
                  Text(
                    'No devices yet. Tap Start Scan.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (_scanResults.isNotEmpty)
                  ..._scanResults.map((result) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_deviceName(result.device)),
                      subtitle: Text(
                        '${result.device.remoteId.str}  RSSI ${result.rssi}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      trailing: FilledButton(
                        onPressed: () => _connectToDevice(result.device),
                        child: const Text('Connect'),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Send Test Data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _txController,
                  decoration: const InputDecoration(
                    hintText: 'Message to send to ESP32',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _connectedDevice == null ? null : _sendData,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incoming Data', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'What to watch for: permission prompts, matching UUIDs, MTU limits, newline framing, and notification frequency.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  Text(
                    'No packets received yet.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (_logs.isNotEmpty)
                  ..._logs.take(20).map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line, style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImuMetricTile extends StatelessWidget {
  const _ImuMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        border: Border.all(color: WarmClayColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
