import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/translation_record.dart';
import '../services/cloud_tts_service.dart';
import '../services/stt_service.dart';
import '../services/translation_api.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_picker.dart';
import '../widgets/live_camera_card.dart';
import '../widgets/voice_input_sheet.dart';

/// Main text-translation screen.
///
/// Text translation goes through [TranslationApi] (Google Cloud Translation).
/// Voice input uses [SttService], camera scanning uses [LiveCameraCard], and
/// reading the result aloud uses [TtsService].
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen>
    with WidgetsBindingObserver {
  static const _maxChars = 500;

  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _tts = TtsService();
  final _cloudTts = CloudTtsService();
  final _stt = SttService();
  bool _cameraMode = false;
  bool _foreground = true;
  int _requestVersion = 0;
  String? _pendingLiveText;
  bool _liveRequestRunning = false;

  String? _resultText;
  String? _errorMessage;
  bool _isTranslating = false;
  String? _lastRecordId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _requestVersion++;
    _inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    _inputFocus.dispose();
    _tts.dispose();
    _cloudTts.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TranslateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) _stopCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs temporarily make iOS inactive during camera startup.
    if (state == AppLifecycleState.inactive) return;
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _cameraMode) _stopCamera();
  }

  void _stopCamera() {
    _requestVersion++;
    _pendingLiveText = null;
    setState(() {
      _cameraMode = false;
      _isTranslating = false;
    });
  }

  void _startCamera() {
    if (_cameraMode) return;
    _inputFocus.unfocus();
    _requestVersion++;
    _inputController.clear();
    setState(() {
      _cameraMode = true;
      _isTranslating = false;
    });
  }

  Future<void> _onLiveText(String text) async {
    if (!_cameraMode || !widget.isActive || !_foreground) return;
    _requestVersion++;
    _inputController.text = text;
    _pendingLiveText = text;
    if (_liveRequestRunning) return;
    _liveRequestRunning = true;
    try {
      // One request at a time; intermediate camera readings are replaced.
      while (mounted && _cameraMode && _pendingLiveText != null) {
        _pendingLiveText = null;
        await _translate();
      }
    } finally {
      _liveRequestRunning = false;
    }
  }

  void _onInputChanged() {
    // Clearing the field should clear a stale result/error along with it.
    if (_inputController.text.isEmpty &&
        (_resultText != null || _errorMessage != null)) {
      setState(() {
        _resultText = null;
        _errorMessage = null;
        _lastRecordId = null;
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputFocus.unfocus();
    final state = AppScope.read(context);
    final from = state.sourceLang;
    final to = state.targetLang;
    final version = ++_requestVersion;
    setState(() {
      _isTranslating = true;
      _errorMessage = null;
      _resultText = null;
      _lastRecordId = null;
    });

    try {
      final translated = await TranslationApi.translate(
        text: text,
        from: from,
        to: to,
      );
      if (!mounted || version != _requestVersion) return;

      final record = TranslationRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sourceText: text,
        translatedText: translated,
        sourceLangCode: from,
        targetLangCode: to,
        createdAt: DateTime.now(),
      );
      state.addRecord(record);

      setState(() {
        _resultText = translated;
        _lastRecordId = record.id;
        _isTranslating = false;
      });
    } on TranslationException catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _errorMessage = e.message;
        _isTranslating = false;
      });
    } catch (_) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isTranslating = false;
      });
    }
  }

  void _clear() {
    _requestVersion++;
    _inputController.clear();
    setState(() {
      _resultText = null;
      _errorMessage = null;
      _lastRecordId = null;
      _isTranslating = false;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyResult() async {
    final text = _resultText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast('Copied to clipboard');
  }

  Future<void> _toggleFavorite() async {
    final id = _lastRecordId;
    if (id == null) return;
    final nowFavorite = await AppScope.read(context).toggleFavorite(id);
    if (!mounted) return;
    _toast(nowFavorite ? 'Saved to favorites' : 'Removed from favorites');
  }

  /// Reads the translation aloud: the instant on-device voice for English and
  /// Filipino, and the ElevenLabs cloud voice for dialects the phone can't speak
  /// (Cebuano, Ilocano, Hiligaynon, Waray).
  Future<void> _speakResult() async {
    final text = _resultText;
    if (text == null || text.isEmpty) return;
    final target = AppScope.read(context).targetLang;

    // On-device first (free + instant) — works for English/Filipino.
    if (await _tts.speak(text, target)) return;
    if (!mounted) return;

    // No on-device voice → fall back to the cloud AI voice for the dialect.
    if (!CloudTtsService.isConfigured) {
      _toast('Voice not available for ${languageByCode(target).name}');
      return;
    }
    _toast('Generating ${languageByCode(target).name} voice…');
    final ok = await _cloudTts.speak(text);
    if (!mounted || ok) return;
    _toast('Could not play voice for ${languageByCode(target).name}');
  }

  /// Captures speech and puts it in the input field, then translates it.
  Future<void> _startVoiceInput() async {
    if (_cameraMode) _stopCamera();
    final source = AppScope.read(context).sourceLang;
    final text = await VoiceInputSheet.show(context, _stt, source);
    if (text == null || text.isEmpty || !mounted) return;
    _inputController.text = text;
    await _translate();
  }

  void _languageChanged() {
    _requestVersion++;
    _pendingLiveText = null;
    setState(() {
      _resultText = null;
      _errorMessage = null;
      _lastRecordId = null;
      _isTranslating = false;
    });
    if (_cameraMode && _inputController.text.trim().isNotEmpty) {
      _onLiveText(_inputController.text.trim());
    }
  }

  Future<void> _pickLanguage({required bool isSource}) async {
    final state = AppScope.read(context);
    final code = await showLanguagePicker(
      context,
      selectedCode: isSource ? state.sourceLang : state.targetLang,
      title: isSource ? 'Translate from' : 'Translate to',
    );
    if (code == null || !mounted) return;
    isSource ? state.setSourceLang(code) : state.setTargetLang(code);
    _languageChanged();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _Header(
            userName: state.user?.name.split(' ').first ?? 'there',
            sourceCode: state.sourceLang,
            targetCode: state.targetLang,
            onSourceTap: () => _pickLanguage(isSource: true),
            onTargetTap: () => _pickLanguage(isSource: false),
            onSwap: () {
              state.swapLanguages();
              _languageChanged();
            },
            onNotifications: () => _toast('No new notifications'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                if (_cameraMode && widget.isActive && _foreground)
                  LiveCameraCard(onText: _onLiveText, onClose: _stopCamera)
                else
                  _InputCard(
                    controller: _inputController,
                    focusNode: _inputFocus,
                    langCode: state.sourceLang,
                    maxChars: _maxChars,
                    onClear: _clear,
                    onVoice: _startVoiceInput,
                    onCamera: _startCamera,
                  ),
                const SizedBox(height: AppSpacing.md),

                if (_cameraMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isTranslating)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.auto_awesome_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isTranslating
                              ? 'Translating...'
                              : 'Translates automatically',
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    key: const ValueKey('translate-button'),
                    onPressed:
                        _inputController.text.trim().isEmpty || _isTranslating
                        ? null
                        : _translate,
                    icon: _isTranslating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(_isTranslating ? 'Translating…' : 'Translate'),
                  ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorCard(
                    message: _errorMessage!,
                    onRetry: () {
                      if (_cameraMode) {
                        _onLiveText(_inputController.text);
                      } else {
                        _translate();
                      }
                    },
                  ),
                ],

                if (_cameraMode &&
                    _resultText == null &&
                    _errorMessage == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageByCode(state.targetLang).name,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isTranslating
                                ? 'Translating detected text...'
                                : 'Point the camera at words or a sentence. The translation will appear here.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_resultText != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ResultCard(
                    text: _resultText!,
                    langCode: state.targetLang,
                    isFavorite:
                        _lastRecordId != null &&
                        state.history.any(
                          (r) => r.id == _lastRecordId && r.isFavorite,
                        ),
                    onCopy: _copyResult,
                    onSpeak: _speakResult,
                    onFavorite: _toggleFavorite,
                    onShare: () => _toast('Sharing is not wired up yet'),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Other ways to translate',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                _QuickActions(
                  onVoice: _startVoiceInput,
                  onCamera: _startCamera,
                  onInfo: _toast,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.sourceCode,
    required this.targetCode,
    required this.onSourceTap,
    required this.onTargetTap,
    required this.onSwap,
    required this.onNotifications,
  });

  final String userName;
  final String sourceCode;
  final String targetCode;
  final VoidCallback onSourceTap;
  final VoidCallback onTargetTap;
  final VoidCallback onSwap;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.g_translate_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Language Bridge',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNotifications,
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: Colors.white,
                    tooltip: 'Notifications',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Hi $userName 👋',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LanguageSwapBar(
                sourceCode: sourceCode,
                targetCode: targetCode,
                onSourceTap: onSourceTap,
                onTargetTap: onTargetTap,
                onSwap: onSwap,
                onLight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- input card

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.langCode,
    required this.maxChars,
    required this.onClear,
    required this.onVoice,
    required this.onCamera,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String langCode;
  final int maxChars;
  final VoidCallback onClear;
  final VoidCallback onVoice;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = languageByCode(langCode);
    final length = controller.text.characters.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lang.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Clear',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 6,
              minLines: 3,
              maxLength: maxChars,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.45),
              decoration: const InputDecoration(
                hintText: 'Enter text to translate…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
            const Divider(height: AppSpacing.lg),
            // Wrap rather than Row: at large text scales the counter drops to
            // its own line instead of overflowing the card.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconAction(
                      icon: Icons.mic_none_rounded,
                      label: 'Voice',
                      onTap: onVoice,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _IconAction(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: onCamera,
                    ),
                  ],
                ),
                Text(
                  '$length / $maxChars',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: length >= maxChars
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.brand),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- result card

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.text,
    required this.langCode,
    required this.isFavorite,
    required this.onCopy,
    required this.onSpeak,
    required this.onFavorite,
    required this.onShare,
  });

  final String text;
  final String langCode;
  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onSpeak;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = languageByCode(langCode);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lang.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Google Translate',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              text,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy',
                ),
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  tooltip: 'Listen',
                ),
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 22,
                    color: isFavorite ? const Color(0xFFF59E0B) : null,
                  ),
                  tooltip: isFavorite ? 'Remove favorite' : 'Save to favorites',
                ),
                const Spacer(),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- error card

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translation failed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ quick actions

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onVoice,
    required this.onCamera,
    required this.onInfo,
  });

  final VoidCallback onVoice;
  final VoidCallback onCamera;
  final void Function(String message) onInfo;

  @override
  Widget build(BuildContext context) {
    final items =
        <({IconData icon, String title, String subtitle, VoidCallback onTap})>[
          (
            icon: Icons.record_voice_over_rounded,
            title: 'Voice',
            subtitle: 'Speak to translate',
            onTap: onVoice,
          ),
          (
            icon: Icons.document_scanner_rounded,
            title: 'Camera',
            subtitle: 'Translate text live',
            onTap: onCamera,
          ),
          (
            icon: Icons.forum_rounded,
            title: 'Conversation',
            subtitle: 'Two-way chat',
            onTap: () => onInfo('Conversation mode is coming next'),
          ),
          (
            icon: Icons.smart_toy_rounded,
            title: 'AI Tutor',
            subtitle: 'Practice a language',
            onTap: () => onInfo('AI assistant needs the Gemini API'),
          ),
        ];

    // A fixed mainAxisExtent keeps tile height stable across screen widths;
    // childAspectRatio would shrink the height on narrow phones and clip.
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 128,
      ),
      children: [
        for (final item in items)
          _QuickActionTile(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            onTap: item.onTap,
          ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: AppColors.brand),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
