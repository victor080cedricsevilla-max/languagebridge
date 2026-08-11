import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/stt_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that runs one speech-to-text session and returns the recognized
/// text via `Navigator.pop` (or null if cancelled / nothing was said).
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
      builder: (_) => VoiceInputSheet(stt: stt, langCode: langCode),
    );
  }

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet> {
  String _text = '';
  bool _listening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final ready = await widget.stt.init();
    if (!mounted) return;
    if (!ready) {
      setState(() => _error =
          'Speech recognition is not available on this device.');
      return;
    }
    setState(() {
      _listening = true;
      _error = null;
    });
    final started = await widget.stt.listen(
      langCode: widget.langCode,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _text = text);
        if (isFinal) _finish();
      },
    );
    if (!started && mounted) {
      setState(() {
        _error = 'Could not start listening. Check the microphone permission.';
        _listening = false;
      });
    }
  }

  Future<void> _finish() async {
    await widget.stt.stop();
    if (!mounted) return;
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (hasError ? AppColors.danger : AppColors.brand)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? Icons.mic_off_rounded : Icons.mic_rounded,
              size: 36,
              color: hasError ? AppColors.danger : AppColors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _error ??
                (_listening
                    ? 'Listening… speak in ${lang.name}'
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              if (!hasError) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _finish,
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
