import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  bool _isScanning = false;
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      setState(() {
        _adapterState = state;
      });
    });
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _notifySub?.cancel();
    _txController.dispose();
    unawaited(_disconnectCurrent());
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      _setStatus('Bluetooth is OFF. Turn it on first.');
      return;
    }

    _scanSub?.cancel();
    _scanResults.clear();
    _setStatus('Scanning...');

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
    });

    setState(() {
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      _setStatus('Scan failed: $e');
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });
    _setStatus('Scan complete');
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });
    _setStatus('Scan stopped');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    await _disconnectCurrent();

    _setStatus('Connecting to ${_deviceName(device)}...');

    try {
      await device.connect(timeout: const Duration(seconds: 12));
    } catch (e) {
      // Device may already be connected from a prior session; otherwise surface the error.
      if (!e.toString().toLowerCase().contains('already')) {
        _setStatus('Connect failed: $e');
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
    } catch (_) {}
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
