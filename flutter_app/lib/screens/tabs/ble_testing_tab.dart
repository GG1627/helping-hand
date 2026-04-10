import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/warm_clay_theme.dart';
import '../../widgets/hand_visualizer_widget.dart';
import '../../widgets/warm_components.dart';

class BleTestingTab extends StatefulWidget {
  const BleTestingTab({super.key});

  @override
  State<BleTestingTab> createState() => _BleTestingTabState();
}

class _BleTestingTabState extends State<BleTestingTab> {
  // ESP32 BLE UART defaults (Nordic UART profile)
  static const String _targetDeviceName = 'HelpingHand-Glove';
  static final Guid _serviceUuid = Guid(
    '6E400001-B5A3-F393-E0A9-E50E24DCCA9E',
  );
  static final Guid _notifyUuid = Guid(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );
  static const List<String> _flexLabels = [
    'Thumb',
    'Index',
    'Middle',
    'Ring',
    'Pinky',
  ];
  static const List<int> _straightRaw = [550, 550, 550, 550, 560];
  static const List<int> _bentRaw = [145, 135, 130, 125, 95];

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? _connectedDevice;
  final List<ScanResult> _scanResults = [];

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  bool _isScanning = false;
  bool _scanRequestInFlight = false;
  bool _autoConnectEnabled = true;
  bool _autoConnectInProgress = false;
  String _status = 'Idle';
  int _targetFoundCount = 0;

  String _predictedLabel = '--';
  double? _predictedConfidence;
  String _expectedLabel = '--';
  String _imuWhoAmI = '--';
  double? _ax;
  double? _ay;
  double? _az;
  double? _gx;
  double? _gy;
  double? _gz;
  final List<int?> _flexRaw = List<int?>.filled(5, null);
  final List<double?> _flexNorm = List<double?>.filled(5, null);
  DateTime? _lastImuUpdate;
  int _packetCount = 0;
  String _lastPacket = '--';

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
    unawaited(_disconnectCurrent());
    super.dispose();
  }

  void _debug(String message) {
    debugPrint('[BLE_TAB] $message');
  }

  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    _debug(
      'Permissions scan=${statuses[Permission.bluetoothScan]} connect=${statuses[Permission.bluetoothConnect]}',
    );

    final hasScan = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final hasConnect =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;

    if (!(hasScan && hasConnect)) {
      _setStatus('Missing BLE permissions (Nearby Devices).');
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
    _targetFoundCount = 0;
    _setStatus('Scanning...');
    _debug('Starting scan...');
    setState(() {
      _isScanning = true;
    });

    _scanSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (!mounted) return;

        BluetoothDevice? autoConnectCandidate;

        setState(() {
          for (final result in results) {
            if (!_isTargetResult(result)) {
              continue;
            }

            final index = _scanResults.indexWhere(
              (item) => item.device.remoteId == result.device.remoteId,
            );
            if (index == -1) {
              _scanResults.add(result);
            } else {
              _scanResults[index] = result;
            }

            _targetFoundCount += 1;

            if (autoConnectCandidate == null && _connectedDevice == null) {
              autoConnectCandidate = result.device;
            }
          }
        });

        if (_autoConnectEnabled &&
            !_autoConnectInProgress &&
            _connectedDevice == null &&
            autoConnectCandidate != null) {
          _autoConnectInProgress = true;
          _setStatus('Target found. Auto-connecting...');
          _debug('Auto-connect starting for ${autoConnectCandidate!.remoteId.str}');
          unawaited(
            _connectToDevice(autoConnectCandidate!).whenComplete(() {
              _autoConnectInProgress = false;
            }),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _debug('Scan stream error: $error');
        _setStatus('Scan stream error: $error');
      },
      onDone: () {
        _debug('Scan stream closed');
      },
    );

    bool scanStarted = false;
    try {
      // Some Android builds report location-services checks inconsistently.
      // Start with non-location BLE scan mode.
      await FlutterBluePlus.startScan(
        withServices: [_serviceUuid],
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );
      scanStarted = true;
      _debug('startScan returned (scan active until stop)');
    } catch (e) {
      _debug('Primary scan failed: $e');

      final needsFineLocation = e.toString().toLowerCase().contains(
        'access fine location required',
      );

      if (needsFineLocation) {
        _debug('Fine location fallback requested by device/OS');
        final status = await Permission.locationWhenInUse.request();
        _debug('Fine location permission: $status');

        if (status.isGranted) {
          try {
            await FlutterBluePlus.startScan(
              withServices: [_serviceUuid],
              androidScanMode: AndroidScanMode.lowLatency,
              androidUsesFineLocation: true,
              androidCheckLocationServices: false,
            );
            scanStarted = true;
            _debug('Fallback scan started with fine location');
          } catch (fallbackError) {
            _debug('Fallback scan failed: $fallbackError');
          }
        }
      }
    }

    if (!scanStarted) {
      _setStatus('Scan failed. Check Nearby Devices (and Location on older Android).');
      setState(() {
        _isScanning = false;
      });
      _scanRequestInFlight = false;
      return;
    }

    _scanRequestInFlight = false;
    _setStatus('Scanning for $_targetDeviceName...');
  }

  Future<void> _stopScan() async {
    _debug('Stopping scan');
    await FlutterBluePlus.stopScan();
    _setStatus('Scan stopped');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice?.remoteId == device.remoteId) {
      _setStatus('Already connected to ${_deviceName(device)}');
      return;
    }

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
        });
        _debug('Device disconnected');

        if (_autoConnectEnabled) {
          _setStatus('Disconnected. Auto-reconnecting...');
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 500), () async {
              if (!mounted) return;
              await _startScan();
            }),
          );
        }
      }
    });

    final services = await device.discoverServices();
    BluetoothCharacteristic? notify;

    for (final service in services) {
      if (service.uuid != _serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _notifyUuid) notify = characteristic;
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
        _tryUpdateFromPacket(text);
      });
    });

    if (!mounted) return;
    setState(() {
      _connectedDevice = device;
    });
    _setStatus('Connected and listening');
    _debug('Connected + notify subscribed');
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

  bool _isTargetResult(ScanResult result) {
    final advName = result.advertisementData.advName.trim().toLowerCase();
    final platformName = result.device.platformName.trim().toLowerCase();
    final target = _targetDeviceName.toLowerCase();
    final hasTargetName = advName == target || platformName == target;
    final hasNusService =
        result.advertisementData.serviceUuids.contains(_serviceUuid);
    return hasTargetName || hasNusService;
  }

  void _tryUpdateFromPacket(String packet) {
    final segments = packet.split(',');
    final parsed = <String, String>{};
    for (final segment in segments) {
      final parts = segment.split('=');
      if (parts.length != 2) continue;
      parsed[parts[0].trim()] = parts[1].trim();
    }

    _imuWhoAmI = parsed['who'] ?? _imuWhoAmI;
    _ax = double.tryParse(parsed['ax'] ?? '') ?? _ax;
    _ay = double.tryParse(parsed['ay'] ?? '') ?? _ay;
    _az = double.tryParse(parsed['az'] ?? '') ?? _az;
    _gx = double.tryParse(parsed['gx'] ?? '') ?? _gx;
    _gy = double.tryParse(parsed['gy'] ?? '') ?? _gy;
    _gz = double.tryParse(parsed['gz'] ?? '') ?? _gz;

    for (var i = 0; i < 5; i++) {
      final raw = double.tryParse(parsed['flex${i}_raw'] ?? '');
      final norm = double.tryParse(parsed['flex${i}_norm'] ?? '');
      if (raw != null) _flexRaw[i] = raw.round();
      if (norm != null) _flexNorm[i] = norm;
    }

    _predictedLabel = parsed['pred'] ?? _predictedLabel;
    _predictedConfidence =
        double.tryParse(parsed['pred_conf'] ?? '') ?? _predictedConfidence;
    _expectedLabel = parsed['expected'] ?? _expectedLabel;

    _packetCount += 1;
    _lastImuUpdate = DateTime.now();
    _lastPacket = packet;
  }

  String _fmt3(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(3);
  }

  String _fmtPct(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
  }

  String _lastUpdateText() {
    final last = _lastImuUpdate;
    if (last == null) return 'No packets parsed yet';
    final seconds = DateTime.now().difference(last).inSeconds;
    if (seconds <= 0) return 'Updated just now';
    return 'Updated ${seconds}s ago';
  }

  List<double> _handBendValues() {
    return List<double>.generate(5, (i) {
      final raw = _flexRaw[i];
      if (raw == null) return 0.0;

      final straight = _straightRaw[i].toDouble();
      final bent = _bentRaw[i].toDouble();
      final denom = straight - bent;
      if (denom.abs() < 1e-6) return 0.0;

      final bend = (straight - raw) / denom;
      return bend.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      title: 'BLE Testing',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: HandVisualizerWidget(
              bendValues: _handBendValues(),
              imuRoll: 0.0,
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLE Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Adapter: ${_adapterState.name} | ${_connectedDevice == null ? 'Not connected' : 'Connected'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Target: $_targetDeviceName',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-connect'),
                  subtitle: const Text('Connect immediately when target is found'),
                  value: _autoConnectEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoConnectEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
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
                    if (_connectedDevice == null && _scanResults.isNotEmpty)
                      OutlinedButton(
                        onPressed: () => _connectToDevice(_scanResults.first.device),
                        child: const Text('Manual Connect'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Targets seen: $_targetFoundCount | In list: ${_scanResults.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Telemetry',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Prediction: $_predictedLabel (${_fmtPct(_predictedConfidence)}) | Expected: $_expectedLabel',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'WHO_AM_I: $_imuWhoAmI | Packets: $_packetCount | ${_lastUpdateText()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 420 ? 3 : 2;
                    final imuItems = [
                      ('Accel X (g)', _fmt3(_ax)),
                      ('Accel Y (g)', _fmt3(_ay)),
                      ('Accel Z (g)', _fmt3(_az)),
                      ('Gyro X (dps)', _fmt3(_gx)),
                      ('Gyro Y (dps)', _fmt3(_gy)),
                      ('Gyro Z (dps)', _fmt3(_gz)),
                    ];
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: imuItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.7,
                      ),
                      itemBuilder: (context, index) {
                        final item = imuItems[index];
                        return _ImuMetricTile(label: item.$1, value: item.$2);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 420 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                      ),
                      itemBuilder: (context, i) {
                        return _FlexMetricTile(
                          label: _flexLabels[i],
                          raw: _flexRaw[i],
                          norm: _flexNorm[i],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: WarmClayTheme.cardGap),
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Packet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _lastPacket,
                  style: Theme.of(context).textTheme.labelSmall,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        border: Border.all(color: WarmClayColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FlexMetricTile extends StatelessWidget {
  const _FlexMetricTile({
    required this.label,
    required this.raw,
    required this.norm,
  });

  final String label;
  final int? raw;
  final double? norm;

  @override
  Widget build(BuildContext context) {
    final displayNorm = norm == null ? '--' : norm!.toStringAsFixed(3);
    final progress = (norm ?? 0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarmClayColors.surface,
        border: Border.all(color: WarmClayColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            'raw: ${raw ?? '--'}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text('norm: $displayNorm', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: WarmClayColors.accentLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                WarmClayColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
