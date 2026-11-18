import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for rootBundle
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/ble_packet.dart';

class ArmatureHand3DViewer extends StatefulWidget {
  const ArmatureHand3DViewer({
    super.key,
    required this.packet,
    this.imuRoll = 0.0,
    this.forceMockStream = true,
  });

  final BlePacket? packet;
  final double imuRoll;
  final bool forceMockStream;

  @override
  State<ArmatureHand3DViewer> createState() => _ArmatureHand3DViewerState();
}

class _ArmatureHand3DViewerState extends State<ArmatureHand3DViewer> {
  late final WebViewController _webController;
  bool _isInitialized = false;

  Timer? _mockTimer;
  double _mockAnimationTick = 0.0;

  static const List<int> _straightRaw = [550, 550, 550, 550, 560];
  static const List<int> _bentRaw = [145, 135, 130, 125, 95];

  @override
  void initState() {
    super.initState();
    
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E22))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            debugPrint('[ArmatureViewer] WebView finished loading. Injecting model bytes...');
            await _injectModelIntoWebView();
            
            setState(() {
              _isInitialized = true;
            });
            _updatePoseInWebView();
            
            if (widget.forceMockStream && widget.packet == null) {
              _startMockStream();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[ArmatureViewer] WebView ERROR: ${error.errorCode}, ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/three_hand_viewer.html');

    _webController = controller;
  }

  Future<void> _injectModelIntoWebView() async {
    try {
      // Correct path: if declared as '- assets/models/test.glb' in pubspec.yaml,
      // loadFlutterAsset or rootBundle expects 'models/test.glb' or the exact path.
      // Let's use 'models/test.glb' to prevent duplication.
      final ByteData data = await rootBundle.load('assets/models/test.glb');
      final Uint8List bytes = data.buffer.asUint8List();
      final String base64Model = base64Encode(bytes);

      await _webController.runJavaScript('window.loadGltfFromBase64("$base64Model");');
      debugPrint('[ArmatureViewer] Successfully injected model base64 into WebView.');
    } catch (e) {
      debugPrint('[ArmatureViewer] Failed to load/inject test.glb bytes: $e');
    }
  }

  void _startMockStream() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isInitialized) return;
      setState(() {
        _mockAnimationTick += 0.05;
      });
      _updatePoseInWebView();
    });
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ArmatureHand3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.packet != null) {
      _mockTimer?.cancel();
    } else if (widget.forceMockStream && _mockTimer?.isActive != true) {
      _startMockStream();
    }

    if (_isInitialized) {
      _updatePoseInWebView();
    }
  }

  double _calculateFlexNorm(int index, int? raw) {
    if (raw == null) return 0.0;
    final straight = _straightRaw[index].toDouble();
    final bent = _bentRaw[index].toDouble();
    return ((straight - raw) / (straight - bent)).clamp(0.0, 1.0);
  }

  void _updatePoseInWebView() {
    double thumb, index, middle, ring, pinky, pitchDeg, rollDeg;

    final packet = widget.packet;
    if (packet == null && widget.forceMockStream) {
      thumb = (math.sin(_mockAnimationTick) + 1) / 2;
      index = (math.sin(_mockAnimationTick + 0.5) + 1) / 2;
      middle = (math.sin(_mockAnimationTick + 1.0) + 1) / 2;
      ring = (math.sin(_mockAnimationTick + 1.5) + 1) / 2;
      pinky = (math.sin(_mockAnimationTick + 2.0) + 1) / 2;
      
      pitchDeg = math.sin(_mockAnimationTick * 0.5) * 20.0;
      rollDeg = math.cos(_mockAnimationTick * 0.5) * 30.0;
    } else {
      thumb = _calculateFlexNorm(0, packet?.flexRaw[0]);
      index = _calculateFlexNorm(1, packet?.flexRaw[1]);
      middle = _calculateFlexNorm(2, packet?.flexRaw[2]);
      ring = _calculateFlexNorm(3, packet?.flexRaw[3]);
      pinky = _calculateFlexNorm(4, packet?.flexRaw[4]);

      rollDeg = widget.imuRoll * (180.0 / math.pi);
      pitchDeg = packet?.ax != null ? packet!.ax! * 45.0 : 0.0;
    }

    final stateMap = {
      'thumb': thumb,
      'index': index,
      'middle': middle,
      'ring': ring,
      'pinky': pinky,
      'pitch': pitchDeg,
      'roll': rollDeg,
    };

    final jsonStr = jsonEncode(stateMap);
    _webController.runJavaScript('window.updateHandPose($jsonStr);');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: RepaintBoundary(
          child: WebViewWidget(controller: _webController),
        ),
      ),
    );
  }
}