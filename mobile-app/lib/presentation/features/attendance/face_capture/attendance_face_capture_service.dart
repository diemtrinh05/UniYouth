import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class CapturedFaceImage {
  const CapturedFaceImage({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final List<int> bytes;
  final String mimeType;
  final String fileName;
}

class CapturedLivenessFrame {
  const CapturedLivenessFrame({
    required this.frameIndex,
    required this.capturedAtMs,
    required this.bytes,
  });

  final int frameIndex;
  final int capturedAtMs;
  final List<int> bytes;
}

class CapturedLivenessPayload {
  const CapturedLivenessPayload({
    required this.mode,
    required this.frameCount,
    required this.mimeType,
    required this.frames,
  });

  final String mode;
  final int frameCount;
  final String mimeType;
  final List<CapturedLivenessFrame> frames;
}

class CapturedFaceEvidence {
  const CapturedFaceEvidence({required this.faceImage, required this.liveness});

  final CapturedFaceImage faceImage;
  final CapturedLivenessPayload liveness;
}

enum FaceCaptureFlowMode { checkIn, enroll }

abstract class AttendanceFaceCaptureService {
  Future<CapturedFaceEvidence?> captureFaceEvidence(
    BuildContext context, {
    FaceCaptureFlowMode flowMode = FaceCaptureFlowMode.checkIn,
  });
}

class CameraAttendanceFaceCaptureService
    implements AttendanceFaceCaptureService {
  @override
  Future<CapturedFaceEvidence?> captureFaceEvidence(
    BuildContext context, {
    FaceCaptureFlowMode flowMode = FaceCaptureFlowMode.checkIn,
  }) {
    return Navigator.of(context).push<CapturedFaceEvidence>(
      MaterialPageRoute<CapturedFaceEvidence>(
        builder: (_) => _AttendanceLivenessCapturePage(flowMode: flowMode),
        fullscreenDialog: true,
      ),
    );
  }
}

class _AttendanceLivenessCapturePage extends StatefulWidget {
  const _AttendanceLivenessCapturePage({required this.flowMode});

  final FaceCaptureFlowMode flowMode;

  @override
  State<_AttendanceLivenessCapturePage> createState() =>
      _AttendanceLivenessCapturePageState();
}

class _AttendanceLivenessCapturePageState
    extends State<_AttendanceLivenessCapturePage> {
  static const String _jpegMimeType = 'image/jpeg';
  static const String _captureMode = 'passive_auto_burst';
  static const String _enrollCaptureMode = 'single_face_enroll';
  static const int _burstFrameCount = 3;
  static const Duration _captureWarmupDelay = Duration(milliseconds: 700);
  static const Duration _captureInterval = Duration(milliseconds: 350);
  static const int _maxFrameBytes = 150 * 1024;
  static const int _maxTotalBytes = 450 * 1024;
  static const int _maxDimension = 720;
  static const int _minBurstDurationMs = 400;
  static const int _maxBurstDurationMs = 4000;
  static const int _minInterFrameGapMs = 120;
  static const int _maxInterFrameGapMs = 2500;
  static const int _enrollCountdownSeconds = 3;
  static const double _minFaceWidthRatio = 0.18;
  static const double _maxFaceWidthRatio = 0.62;
  static const double _minFaceHeightRatio = 0.24;
  static const double _maxFaceHeightRatio = 0.78;
  static const double _minFaceCenterXRatio = 0.30;
  static const double _maxFaceCenterXRatio = 0.70;
  static const double _minFaceCenterYRatio = 0.24;
  static const double _maxFaceCenterYRatio = 0.66;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isStreamingFrames = false;
  bool _isProcessingFrame = false;
  String? _errorMessage;
  int _capturedFrames = 0;
  int? _countdownSeconds;
  _FaceAlignmentState _faceAlignmentState = _FaceAlignmentState.unknown;
  Completer<void>? _faceAlignedCompleter;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCameraAndCapture());
  }

  @override
  void dispose() {
    unawaited(_disposeResources());
    super.dispose();
  }

  Future<void> _disposeResources() async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }

    await _faceDetector.close();
  }

  Future<void> _initializeCameraAndCapture() async {
    await _disposeActiveController();
    _faceAlignedCompleter = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _isCapturing = false;
      _errorMessage = null;
      _capturedFrames = 0;
      _faceAlignmentState = _FaceAlignmentState.unknown;
      _countdownSeconds = widget.flowMode == FaceCaptureFlowMode.enroll
          ? _enrollCountdownSeconds
          : null;
    });

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.cast<CameraDescription?>().firstWhere(
        (camera) => camera?.lensDirection == CameraLensDirection.front,
        orElse: () => null,
      );

      if (frontCamera == null) {
        throw const _LivenessCaptureException(
          'Thiết bị không có camera trước để quét khuôn mặt.',
        );
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (mounted) {
        _controller = controller;
        setState(() {
          _isInitializing = false;
        });
      }

      await _startFaceAlignmentStream(controller);
      await Future<void>.delayed(_captureWarmupDelay);
      if (!mounted) {
        return;
      }

      await _runPreCaptureGate();
      if (!mounted || _errorMessage != null) {
        return;
      }

      await _stopFaceAlignmentStream();
      if (widget.flowMode == FaceCaptureFlowMode.enroll) {
        await _captureSingleFaceForEnrollment();
      } else {
        await _captureBurst();
      }
    } on CameraException {
      _setFailure(
        'Không thể mở camera trước. Vui lòng thử lại hoặc kiểm tra quyền camera.',
      );
    } on _LivenessCaptureException catch (error) {
      _setFailure(error.message);
    } catch (_) {
      _setFailure('Không thể khởi tạo quét khuôn mặt. Vui lòng thử lại.');
    }
  }

  Future<void> _disposeActiveController() async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}

      try {
        await controller.dispose();
      } catch (_) {}
    }

    _isStreamingFrames = false;
    _isProcessingFrame = false;
  }

  Future<void> _runPreCaptureGate() async {
    if (widget.flowMode != FaceCaptureFlowMode.enroll) {
      await _waitForFaceAligned();
      return;
    }

    while (mounted) {
      await _waitForFaceAligned();
      if (!mounted) {
        return;
      }

      var remaining = _enrollCountdownSeconds;
      while (mounted && remaining >= 1) {
        if (_faceAlignmentState != _FaceAlignmentState.aligned) {
          break;
        }

        setState(() {
          _countdownSeconds = remaining;
        });
        await Future<void>.delayed(const Duration(seconds: 1));

        if (_faceAlignmentState != _FaceAlignmentState.aligned) {
          break;
        }

        remaining -= 1;
      }

      if (!mounted) {
        return;
      }
      if (_faceAlignmentState == _FaceAlignmentState.aligned &&
          remaining == 0) {
        setState(() {
          _countdownSeconds = null;
        });
        return;
      }

      setState(() {
        _countdownSeconds = _enrollCountdownSeconds;
      });
    }
  }

  Future<void> _captureBurst() async {
    final controller = _controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
      _capturedFrames = 0;
    });

    try {
      _ensureFrameAlignmentReady();
      final capturedFrames = <CapturedLivenessFrame>[];
      DateTime? firstTimestamp;
      var totalBytes = 0;

      for (var frameIndex = 0; frameIndex < _burstFrameCount; frameIndex++) {
        if (frameIndex > 0) {
          await Future<void>.delayed(_captureInterval);
        }

        final timestamp = DateTime.now();
        final picture = await controller.takePicture();
        final rawBytes = await picture.readAsBytes();
        final normalizedBytes = _normalizeFrame(rawBytes);

        if (normalizedBytes == null || normalizedBytes.isEmpty) {
          throw const _LivenessCaptureException(
            'Không xử lý được ảnh khuôn mặt vừa quét. Vui lòng thử lại.',
          );
        }

        if (normalizedBytes.length > _maxFrameBytes) {
          throw const _LivenessCaptureException(
            'Ảnh liveness quá lớn. Vui lòng giữ máy ổn định rồi thử lại.',
          );
        }

        totalBytes += normalizedBytes.length;
        if (totalBytes > _maxTotalBytes) {
          throw const _LivenessCaptureException(
            'Dữ liệu liveness vượt giới hạn cho phép. Vui lòng thử lại.',
          );
        }

        firstTimestamp ??= timestamp;
        capturedFrames.add(
          CapturedLivenessFrame(
            frameIndex: frameIndex,
            capturedAtMs: timestamp.difference(firstTimestamp).inMilliseconds,
            bytes: normalizedBytes.toList(growable: false),
          ),
        );

        if (!mounted) {
          return;
        }
        setState(() {
          _capturedFrames = frameIndex + 1;
        });
      }

      _validateBurstTiming(capturedFrames);

      final pivotFrame = capturedFrames[capturedFrames.length ~/ 2];
      final faceImage = CapturedFaceImage(
        bytes: pivotFrame.bytes,
        mimeType: _jpegMimeType,
        fileName: 'face_liveness_capture.jpg',
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        CapturedFaceEvidence(
          faceImage: faceImage,
          liveness: CapturedLivenessPayload(
            mode: _captureMode,
            frameCount: capturedFrames.length,
            mimeType: _jpegMimeType,
            frames: capturedFrames,
          ),
        ),
      );
    } on CameraException {
      _setFailure(
        'Không thể quét khuôn mặt bằng camera trước. Vui lòng thử lại.',
      );
    } on _LivenessCaptureException catch (error) {
      _setFailure(error.message);
    } catch (_) {
      _setFailure('Quét khuôn mặt thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _captureSingleFaceForEnrollment() async {
    final controller = _controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
      _capturedFrames = 0;
    });

    try {
      _ensureFrameAlignmentReady();
      final picture = await controller.takePicture();
      final rawBytes = await picture.readAsBytes();
      final normalizedBytes = _normalizeFrame(rawBytes);

      if (normalizedBytes == null || normalizedBytes.isEmpty) {
        throw const _LivenessCaptureException(
          'Không xử lý được ảnh khuôn mặt vừa quét. Vui lòng thử lại.',
        );
      }

      if (normalizedBytes.length > _maxFrameBytes) {
        throw const _LivenessCaptureException(
          'Ảnh khuôn mặt quá lớn. Vui lòng giữ máy ổn định rồi thử lại.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _capturedFrames = 1;
      });

      Navigator.of(context).pop(
        CapturedFaceEvidence(
          faceImage: CapturedFaceImage(
            bytes: normalizedBytes,
            mimeType: _jpegMimeType,
            fileName: 'face_enroll_capture.jpg',
          ),
          liveness: CapturedLivenessPayload(
            mode: _enrollCaptureMode,
            frameCount: 1,
            mimeType: _jpegMimeType,
            frames: [
              CapturedLivenessFrame(
                frameIndex: 0,
                capturedAtMs: 0,
                bytes: normalizedBytes.toList(growable: false),
              ),
            ],
          ),
        ),
      );
    } on CameraException {
      _setFailure(
        'Không thể quét khuôn mặt bằng camera trước. Vui lòng thử lại.',
      );
    } on _LivenessCaptureException catch (error) {
      _setFailure(error.message);
    } catch (_) {
      _setFailure('Quét khuôn mặt thất bại. Vui lòng thử lại.');
    }
  }

  void _ensureFrameAlignmentReady() {
    if (_faceAlignmentState == _FaceAlignmentState.aligned) {
      return;
    }

    throw const _LivenessCaptureException(
      'Giữ khuôn mặt ở đúng khung rồi thử lại để quét liveness.',
    );
  }

  void _validateBurstTiming(List<CapturedLivenessFrame> frames) {
    if (frames.length != _burstFrameCount) {
      throw const _LivenessCaptureException(
        'Burst liveness chưa đủ số frame. Vui lòng thử lại.',
      );
    }

    final totalDurationMs =
        frames.last.capturedAtMs - frames.first.capturedAtMs;
    if (totalDurationMs < _minBurstDurationMs ||
        totalDurationMs > _maxBurstDurationMs) {
      throw const _LivenessCaptureException(
        'Burst liveness chưa ổn định theo thời gian. Vui lòng giữ máy ổn định rồi thử lại.',
      );
    }

    for (var index = 1; index < frames.length; index++) {
      final gap = frames[index].capturedAtMs - frames[index - 1].capturedAtMs;
      if (gap < _minInterFrameGapMs || gap > _maxInterFrameGapMs) {
        throw const _LivenessCaptureException(
          'Các frame liveness được chụp chưa đều. Vui lòng thử lại.',
        );
      }
    }
  }

  void _setFailure(String message) {
    unawaited(_stopFaceAlignmentStream());
    _faceAlignedCompleter = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _isInitializing = false;
      _isCapturing = false;
      _capturedFrames = 0;
      _countdownSeconds = null;
      _errorMessage = message;
    });
  }

  Future<void> _startFaceAlignmentStream(CameraController controller) async {
    if (_isStreamingFrames) {
      return;
    }

    await controller.startImageStream((image) async {
      await _processCameraFrame(image, controller.description);
    });
    _isStreamingFrames = true;
  }

  Future<void> _stopFaceAlignmentStream() async {
    final controller = _controller;
    if (!_isStreamingFrames || controller == null) {
      return;
    }

    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    _isStreamingFrames = false;
    _isProcessingFrame = false;
  }

  Future<void> _waitForFaceAligned() async {
    if (_faceAlignmentState == _FaceAlignmentState.aligned) {
      return;
    }

    final completer = Completer<void>();
    _faceAlignedCompleter = completer;
    await completer.future;
  }

  Future<void> _processCameraFrame(
    CameraImage image,
    CameraDescription description,
  ) async {
    if (_isProcessingFrame || _isCapturing || _errorMessage != null) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final inputImage = _buildInputImage(image, description);
      if (inputImage == null) {
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      final nextState = _resolveFaceAlignmentState(
        faces,
        Size(image.width.toDouble(), image.height.toDouble()),
      );
      _updateFaceAlignmentState(nextState);
    } catch (_) {
      _updateFaceAlignmentState(_FaceAlignmentState.unknown);
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription description,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(
      description.sensorOrientation,
    );
    if (rotation == null) {
      return null;
    }

    final inputImageFormat = InputImageFormatValue.fromRawValue(
      image.format.raw,
    );
    if (inputImageFormat == null) {
      return null;
    }

    if (Platform.isAndroid && inputImageFormat != InputImageFormat.nv21) {
      return null;
    }
    if (Platform.isIOS && inputImageFormat != InputImageFormat.bgra8888) {
      return null;
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  _FaceAlignmentState _resolveFaceAlignmentState(
    List<Face> faces,
    Size imageSize,
  ) {
    if (faces.isEmpty) {
      return _FaceAlignmentState.noFace;
    }
    if (faces.length > 1) {
      return _FaceAlignmentState.multipleFaces;
    }

    final boundingBox = faces.first.boundingBox;
    final faceCenterX = boundingBox.center.dx / imageSize.width;
    final faceCenterY = boundingBox.center.dy / imageSize.height;
    final faceWidthRatio = boundingBox.width / imageSize.width;
    final faceHeightRatio = boundingBox.height / imageSize.height;

    final isCentered =
        faceCenterX >= _minFaceCenterXRatio &&
        faceCenterX <= _maxFaceCenterXRatio &&
        faceCenterY >= _minFaceCenterYRatio &&
        faceCenterY <= _maxFaceCenterYRatio;
    final isSizedCorrectly =
        faceWidthRatio >= _minFaceWidthRatio &&
        faceWidthRatio <= _maxFaceWidthRatio &&
        faceHeightRatio >= _minFaceHeightRatio &&
        faceHeightRatio <= _maxFaceHeightRatio;

    return isCentered && isSizedCorrectly
        ? _FaceAlignmentState.aligned
        : _FaceAlignmentState.outOfFrame;
  }

  void _updateFaceAlignmentState(_FaceAlignmentState nextState) {
    if (!mounted) {
      return;
    }

    if (_faceAlignmentState != nextState) {
      setState(() {
        _faceAlignmentState = nextState;
      });
    }

    if (nextState == _FaceAlignmentState.aligned &&
        _faceAlignedCompleter != null &&
        !(_faceAlignedCompleter?.isCompleted ?? true)) {
      _faceAlignedCompleter?.complete();
      _faceAlignedCompleter = null;
    }
  }

  String _buildInstructionText() {
    if (_errorMessage != null) {
      return _errorMessage!;
    }
    if (_isInitializing) {
      return 'Đang chuẩn bị camera trước...';
    }
    if (_faceAlignmentState == _FaceAlignmentState.noFace) {
      return 'Đưa khuôn mặt vào đúng khung để tiếp tục.';
    }
    if (_faceAlignmentState == _FaceAlignmentState.multipleFaces) {
      return 'Chỉ giữ một khuôn mặt trong khung để tiếp tục.';
    }
    if (_faceAlignmentState == _FaceAlignmentState.outOfFrame) {
      return 'Đưa khuôn mặt vào đúng khung rồi giữ ổn định.';
    }
    if (_countdownSeconds != null) {
      return 'Giữ khuôn mặt trong khung. Ứng dụng sẽ tự chụp sau $_countdownSeconds giây.';
    }
    if (_isCapturing) {
      return 'Giữ khuôn mặt trong khung. Ứng dụng đang tự quét liveness.';
    }
    return 'Giữ khuôn mặt trong khung để ứng dụng tự quét.';
  }

  Color _buildGuideColor() {
    switch (_faceAlignmentState) {
      case _FaceAlignmentState.aligned:
        return const Color(0xFF4CAF50);
      case _FaceAlignmentState.noFace:
      case _FaceAlignmentState.multipleFaces:
      case _FaceAlignmentState.outOfFrame:
        return const Color(0xFFFFB300);
      case _FaceAlignmentState.unknown:
        return Colors.white;
    }
  }

  Uint8List? _normalizeFrame(Uint8List rawBytes) {
    final decodedImage = img.decodeImage(rawBytes);
    if (decodedImage == null) {
      return null;
    }

    var workingImage = decodedImage;
    if (decodedImage.width > _maxDimension ||
        decodedImage.height > _maxDimension) {
      workingImage = img.copyResize(
        decodedImage,
        width: decodedImage.width >= decodedImage.height ? _maxDimension : null,
        height: decodedImage.height > decodedImage.width ? _maxDimension : null,
        interpolation: img.Interpolation.average,
      );
    }

    for (final quality in const <int>[85, 75, 65, 55]) {
      final encoded = img.encodeJpg(workingImage, quality: quality);
      if (encoded.isNotEmpty && encoded.length <= _maxFrameBytes) {
        return Uint8List.fromList(encoded);
      }
    }

    final encoded = img.encodeJpg(workingImage, quality: 45);
    if (encoded.isEmpty) {
      return null;
    }
    return Uint8List.fromList(encoded);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canShowPreview =
        controller != null &&
        controller.value.isInitialized &&
        !_isInitializing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.flowMode == FaceCaptureFlowMode.enroll
              ? 'Đăng ký khuôn mặt'
              : 'Quét khuôn mặt',
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (canShowPreview) CameraPreview(controller),
          if (!canShowPreview) const ColoredBox(color: Colors.black),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _FaceGuideFrame(borderColor: _buildGuideColor()),
                  const Spacer(),
                  Text(
                    _buildInstructionText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isInitializing ||
                      _isCapturing ||
                      _countdownSeconds != null)
                    Column(
                      children: [
                        if (_countdownSeconds != null)
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              '$_countdownSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          _countdownSeconds != null
                              ? 'Chuẩn bị chụp ảnh đăng ký'
                              : _isCapturing
                              ? 'Đã lấy $_capturedFrames/$_burstFrameCount frame'
                              : 'Đang khởi tạo phiên quét liveness',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _initializeCameraAndCapture,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceGuideFrame extends StatelessWidget {
  const _FaceGuideFrame({required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 3),
        ),
        child: Center(
          child: Container(
            width: 180,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(120),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.9),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LivenessCaptureException implements Exception {
  const _LivenessCaptureException(this.message);

  final String message;
}

enum _FaceAlignmentState { unknown, noFace, multipleFaces, outOfFrame, aligned }
