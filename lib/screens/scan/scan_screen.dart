import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:zeno/models/face_scan_entry.dart';
import 'package:zeno/providers/app_state_provider.dart';
import 'package:zeno/theme/app_theme.dart';
import 'package:zeno/widgets/glass_card.dart';
import 'package:zeno/widgets/mochi_widget.dart';
import 'package:zeno/services/face_scan_analyzer.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _scanSeconds = 5;

  final FaceScanAnalyzer _analyzer = FaceScanAnalyzer();
  final List<FaceFrameSignal> _samples = [];

  bool _scanning = false;
  bool _initializingCamera = false;
  bool _complete = false;
  int _countdown = _scanSeconds;
  int _framesProcessed = 0;
  String? _errorText;
  String _statusText = 'Quick check-in with your mind';
  FaceScanEntry? _latestEntry;

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  Timer? _countdownTimer;
  bool _processingFrame = false;

  late final AnimationController _pulseCtrl;

  bool get _androidSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _releaseScanResourcesForRestart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _releaseScanResourcesForRestart();
    }
  }

  Future<void> _startScan() async {
    if (_scanning || _initializingCamera) {
      return;
    }
    if (!_androidSupported) {
      setState(() {
        _errorText = 'Face scan is available on Android only right now.';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _scanning = false;
      _complete = false;
      _countdown = _scanSeconds;
      _framesProcessed = 0;
      _errorText = null;
      _latestEntry = null;
      _statusText = 'Preparing the front camera...';
    });
    _samples.clear();

    try {
      await _prepareCamera();
      if (!mounted || _cameraController == null) {
        return;
      }

      setState(() {
        _scanning = true;
        _statusText = 'Look toward the camera and hold still for a few seconds.';
      });

      await _cameraController!.startImageStream(_processCameraImage);
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_countdown <= 1) {
          timer.cancel();
          _finishScan();
          return;
        }
        setState(() => _countdown -= 1);
      });
    } catch (error) {
      await _stopCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _cameraErrorMessage(error);
        _statusText = 'Mochi could not start the scan.';
        _initializingCamera = false;
      });
    }
  }

  Future<void> _prepareCamera() async {
    setState(() {
      _initializingCamera = true;
      _errorText = null;
    });

    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableContours: true,
      ),
    );

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('no_camera', 'No camera was found on this device.');
    }
    final camera = cameras.firstWhere(
      (candidate) => candidate.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    await _cameraController?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      // ML Kit on Android only accepts NV21 (or YV12) byte buffers.
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
      _initializingCamera = false;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (!_scanning || _processingFrame || _faceDetector == null || _cameraController == null) {
      return;
    }

    final inputImage = _inputImageFromCameraImage(
      image,
      _cameraController!.description,
    );
    if (inputImage == null) {
      return;
    }

    _processingFrame = true;
    _framesProcessed += 1;
    try {
      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) {
        return;
      }
      final face = faces.reduce(
        (current, next) =>
            current.boundingBox.size.longestSide > next.boundingBox.size.longestSide
                ? current
                : next,
      );
      _samples.add(_sampleFromFace(face, image.width.toDouble(), image.height.toDouble()));
    } catch (error) {
      // A single unreadable frame shouldn't end the scan; too few good
      // samples is reported once the countdown finishes.
      debugPrint('Face detection skipped a frame: $error');
    } finally {
      _processingFrame = false;
    }
  }

  FaceFrameSignal _sampleFromFace(Face face, double imageWidth, double imageHeight) {
    final centerX = face.boundingBox.center.dx / imageWidth;
    final centerY = face.boundingBox.center.dy / imageHeight;
    final centeredX = 1 - ((centerX - 0.5).abs() * 2).clamp(0.0, 1.0);
    final centeredY = 1 - ((centerY - 0.5).abs() * 2).clamp(0.0, 1.0);

    return FaceFrameSignal(
      smileProbability: (face.smilingProbability ?? 0.45).clamp(0.0, 1.0),
      leftEyeOpenProbability:
          (face.leftEyeOpenProbability ?? 0.55).clamp(0.0, 1.0),
      rightEyeOpenProbability:
          (face.rightEyeOpenProbability ?? 0.55).clamp(0.0, 1.0),
      headEulerAngleY: face.headEulerAngleY ?? 0,
      headEulerAngleZ: face.headEulerAngleZ ?? 0,
      centeredness: ((centeredX + centeredY) / 2).clamp(0.0, 1.0),
    );
  }

  Future<void> _finishScan() async {
    _countdownTimer?.cancel();
    await _stopCamera();

    if (!mounted) {
      return;
    }

    if (_samples.length < 4) {
      setState(() {
        _scanning = false;
        _complete = false;
        _errorText = 'Mochi could not read your face clearly. Try better light and keep your face centered.';
        _statusText = 'No reliable face sample yet.';
      });
      return;
    }

    final entry = _analyzer.buildEntry(
      samples: _samples,
      framesProcessed: _framesProcessed,
    );
    await ref.read(appStateProvider.notifier).recordFaceScan(entry);
    HapticFeedback.heavyImpact();

    if (!mounted) {
      return;
    }

    setState(() {
      _scanning = false;
      _complete = true;
      _latestEntry = entry;
      _statusText = entry.mochiInsight;
      _errorText = null;
    });
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    // Take the preview off screen before disposing: dispose() marks the
    // controller disposed immediately, and the still-visible CameraPreview
    // would throw on its next frame.
    if (mounted) {
      setState(() {
        _cameraController = null;
        _initializingCamera = false;
      });
    } else {
      _cameraController = null;
      _initializingCamera = false;
    }
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {
        // Camera plugins can already be tearing down during restart.
      }
    }
    try {
      await controller?.dispose();
    } catch (_) {
      // Safe to ignore during engine teardown.
    }
  }

  void _releaseScanResourcesForRestart() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_cameraController == null && !_scanning) {
      return;
    }
    _scanning = false;
    _initializingCamera = false;
    unawaited(_stopCamera());
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription description,
  ) {
    final rotation =
        InputImageRotationValue.fromRawValue(description.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // NV21 frames arrive as a single plane holding the whole image.
    if (rotation == null ||
        format != InputImageFormat.nv21 ||
        image.planes.length != 1) {
      return null;
    }

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  String _cameraErrorMessage(Object error) {
    if (error is CameraException) {
      if (error.code == 'CameraAccessDenied') {
        return 'Camera permission was denied. Enable it to run the face scan.';
      }
      return error.description ?? 'Camera error: ${error.code}';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: pad.top + AppTheme.lg,
        left: AppTheme.lg,
        right: AppTheme.lg,
        bottom: pad.bottom + 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CogniPulse Scan', style: AppTheme.displayMedium)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.1),
          const SizedBox(height: AppTheme.sm),
          Text(
            _androidSupported
                ? 'Quick check-in with your mind'
                : 'Face scan is available on Android only right now.',
            style: AppTheme.bodySmall,
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: AppTheme.xxl),
          Center(
            child: Column(
              children: [
                _buildScanSurface(),
                const SizedBox(height: AppTheme.lg),
                Text(
                  _statusText,
                  style: AppTheme.bodyMedium.copyWith(
                    color: _errorText == null ? AppTheme.textSecondary : AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    _errorText!,
                    style: AppTheme.caption.copyWith(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_complete && _latestEntry != null) ...[
                  const SizedBox(height: AppTheme.lg),
                  _ScanResultCard(entry: _latestEntry!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.xxl),
          if (!_scanning)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _initializingCamera ? null : _startScan,
                child: Text(
                  _complete ? 'Scan Again' : 'Begin Scan',
                  style: AppTheme.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildScanSurface() {
    final controller = _cameraController;
    final showPreview = controller != null && controller.value.isInitialized;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: showPreview
          ? _CameraScanPreview(
              key: const ValueKey('camera'),
              controller: controller,
              countdown: _countdown,
              pulse: _pulseCtrl,
            )
          : SizedBox(
              key: const ValueKey('placeholder'),
              width: 240,
              height: 260,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MochiWidget(size: 120, interactive: false)
                      .animate()
                      .fadeIn(duration: 600.ms),
                  const SizedBox(height: AppTheme.md),
                  Text(
                    _initializingCamera
                        ? 'Opening camera...'
                        : 'Tap begin when you are ready.',
                    style: AppTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CameraScanPreview extends StatelessWidget {
  final CameraController controller;
  final int countdown;
  final AnimationController pulse;

  const _CameraScanPreview({
    super.key,
    required this.controller,
    required this.countdown,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 1 - pulse.value;
        return Container(
          width: 260,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withValues(alpha: 0.12 + glow * 0.18),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.cardRadiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.7),
                      width: 3,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 180,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$countdown',
                      style: AppTheme.headlineMed.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final FaceScanEntry entry;

  const _ScanResultCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppTheme.primarySoft.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Scan Complete',
                style: AppTheme.headlineMed.copyWith(color: AppTheme.primary),
              ),
              const Spacer(),
              Text(
                '${entry.score}',
                style: AppTheme.displaySmall.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Text('CogniPulse Score', style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Mood',
                  value: entry.moodScore.toStringAsFixed(0),
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _MetricPill(
                  label: 'Focus',
                  value: entry.focusLevel.toStringAsFixed(0),
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: _MetricPill(
                  label: 'Stress',
                  value: entry.stressIndex.toStringAsFixed(0),
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            entry.mochiInsight,
            style: AppTheme.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            'Stored locally on this device.',
            style: AppTheme.caption,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headlineMed.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
