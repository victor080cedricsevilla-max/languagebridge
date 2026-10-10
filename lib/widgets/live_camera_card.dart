import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/live_text_filter.dart';

/// Owns the camera and recognizer only while the translation tab is visible.
class LiveCameraCard extends StatefulWidget {
  const LiveCameraCard({
    super.key,
    required this.onText,
    required this.onClose,
  });

  final ValueChanged<String> onText;
  final VoidCallback onClose;

  @override
  State<LiveCameraCard> createState() => _LiveCameraCardState();
}

class _LiveCameraCardState extends State<LiveCameraCard> {
  // A rapidly reopened card waits for the previous native camera to release.
  static Future<void> _previousRelease = Future<void>.value();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _filter = LiveTextFilter();
  CameraController? _camera;
  late final Future<void> _startup;
  Future<void>? _processing;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _closed = false;
  String? _error;
  String _caption = 'Point at text and hold steady';

  @override
  void initState() {
    super.initState();
    _startup = _start();
  }

  Future<void> _start() async {
    await _previousRelease;
    if (_closed) return;
    try {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        throw CameraException(
          'unsupported',
          'Live camera translation is available on Android and iPhone.',
        );
      }
      final cameras = await availableCameras();
      if (_closed) return;
      if (cameras.isEmpty) {
        throw CameraException('missing', 'No camera was found.');
      }
      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _camera = camera;
      await camera.initialize();
      if (_closed) return;
      await camera.startImageStream(_onFrame);
      if (!_closed) setState(() {});
    } on CameraException catch (error) {
      if (_closed) return;
      setState(() {
        _error = error.code.contains('Access')
            ? 'Camera access is unavailable. Allow camera access in Settings, then reopen the camera.'
            : error.description ?? 'Could not open the camera.';
      });
    } catch (_) {
      if (!_closed) {
        setState(
          () => _error = 'Could not open the camera. Close it and try again.',
        );
      }
    }
  }

  void _onFrame(CameraImage frame) {
    if (_closed || _processing != null || _error != null) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame).inMilliseconds < 650) return;
    _lastFrame = now;
    _processing = _readFrame(frame).whenComplete(() => _processing = null);
  }

  Future<void> _readFrame(CameraImage frame) async {
    try {
      final camera = _camera!;
      final android = defaultTargetPlatform == TargetPlatform.android;
      final format = InputImageFormatValue.fromRawValue(frame.format.raw);
      if (frame.planes.length != 1 ||
          format !=
              (android ? InputImageFormat.nv21 : InputImageFormat.bgra8888)) {
        throw StateError('Unsupported camera image format');
      }
      const orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      final sensor = camera.description.sensorOrientation;
      final device = orientations[camera.value.deviceOrientation]!;
      final degrees = !android
          ? sensor
          : camera.description.lensDirection == CameraLensDirection.front
          ? (sensor + device) % 360
          : (sensor - device + 360) % 360;
      final plane = frame.planes.single;
      final input = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(degrees)!,
          format: format!,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      final recognized = await _recognizer.processImage(input);
      if (_closed) return;
      final text = recognized.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      final limited = text.characters.take(500).toString();
      final stable = _filter.add(limited);
      setState(() {
        _caption = text.isEmpty ? 'Point at text and hold steady' : limited;
      });
      if (stable != null) widget.onText(stable);
    } catch (_) {
      if (!_closed) {
        setState(
          () => _error =
              'Could not read the camera feed. Close it and try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    _closed = true;
    _previousRelease = _release().catchError((Object error) {
      debugPrint('Camera cleanup failed: $error');
    });
    unawaited(_previousRelease);
    super.dispose();
  }

  Future<void> _release() async {
    // Initialization and OCR must finish before their native resources close.
    await _startup;
    try {
      if (_camera?.value.isStreamingImages ?? false) {
        await _camera!.stopImageStream();
      }
      await _processing;
    } finally {
      try {
        await _camera?.dispose();
      } finally {
        await _recognizer.close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 280,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (_error == null && camera != null && camera.value.isInitialized)
              LayoutBuilder(
                builder: (context, constraints) {
                  final portrait =
                      camera.value.deviceOrientation ==
                          DeviceOrientation.portraitUp ||
                      camera.value.deviceOrientation ==
                          DeviceOrientation.portraitDown;
                  final size = camera.value.previewSize!;
                  return ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: portrait ? size.height : size.width,
                        height: portrait ? size.width : size.height,
                        child: CameraPreview(camera),
                      ),
                    ),
                  );
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: _error == null
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ColoredBox(
                color: Colors.black54,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.videocam_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Live camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      tooltip: 'Back to typing',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error == null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
