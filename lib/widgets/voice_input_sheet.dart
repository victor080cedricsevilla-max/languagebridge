import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/stt_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet with a press-and-hold mic button: hold to record, release to
/// finish. Resolves via `Navigator.pop` to the recognized text (or null if
/// cancelled / nothing was said).
class VoiceInputSheet extends StatefulWidget {
  const VoiceInputSheet({super.key, required this.stt, required this.langCode});

  final SttService stt;
  final String langCode;

  /// Opens the sheet and resolves to the recognized text (or null).
  static Future<String?> show(
    BuildContext context,
    SttService stt,
    String langCode,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      builder: (_) => VoiceInputSheet(stt: stt, langCode: langCode),
    );
  }

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  String _text = '';
  bool _ready = false;
  bool _listening = false;
  bool _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final ready = await widget.stt.init();
    if (!mounted) return;
    setState(() {
      _ready = ready;
      if (!ready) {
        _error = 'Speech recognition is not available on this device.';
      }
    });
  }

  Future<void> _startListening() async {
    if (!_ready || _listening) return;
    setState(() {
      _listening = true;
      _text = '';
      _error = null;
    });
    final started = await widget.stt.listen(
      langCode: widget.langCode,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _text = text);
        if (isFinal) _stopListening();
      },
    );
    if (!started && mounted) {
      setState(() {
        _error = 'Could not start listening. Check the microphone permission.';
        _listening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await widget.stt.stop();
    if (!mounted) return;
    setState(() => _listening = false);
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop(_text.trim().isEmpty ? null : _text.trim());
  }

  @override
  void dispose() {
    widget.stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = languageByCode(widget.langCode);
    final hasError = _error != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: hasError || !_ready ? null : (_) => _startListening(),
            onTapUp: hasError ? null : (_) => _stopListening(),
            onTapCancel: hasError ? null : _stopListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hasError
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.brand.withValues(alpha: _listening ? 1 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError ? Icons.mic_off_rounded : Icons.mic_rounded,
                size: 36,
                color: hasError
                    ? AppColors.danger
                    : _listening
                        ? Colors.white
                        : AppColors.brand,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ??
                (_listening
                    ? 'Listening… speak in ${lang.name}'
                    : _ready
                        ? 'Hold the mic button to speak'
                        : 'Starting…'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (!hasError) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _text.isEmpty ? '…' : _text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
