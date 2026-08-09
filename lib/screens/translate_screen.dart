import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_state.dart';
import '../data/fake_translator.dart';
import '../data/mock_data.dart';
import '../models/translation_record.dart';
import '../theme/app_theme.dart';
import '../widgets/language_picker.dart';

/// Main text-translation screen.
///
/// The translation call goes through [FakeTranslator]; swap that for the real
/// Translation API client and this screen needs no other change.
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  static const _maxChars = 500;

  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  TranslationResult? _result;
  bool _isTranslating = false;
  String? _lastRecordId;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    // Clearing the field should clear a stale result along with it.
    if (_inputController.text.isEmpty && _result != null) {
      setState(() {
        _result = null;
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
    setState(() => _isTranslating = true);

    final result = await FakeTranslator.translate(
      text: text,
      from: state.sourceLang,
      to: state.targetLang,
    );
    if (!mounted) return;

    final record = TranslationRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sourceText: text,
      translatedText: result.text,
      sourceLangCode: state.sourceLang,
      targetLangCode: state.targetLang,
      createdAt: DateTime.now(),
    );
    state.addRecord(record);

    setState(() {
      _result = result;
      _lastRecordId = record.id;
      _isTranslating = false;
    });
  }

  void _clear() {
    _inputController.clear();
    setState(() {
      _result = null;
      _lastRecordId = null;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyResult() async {
    final text = _result?.text;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast('Copied to clipboard');
  }

  void _toggleFavorite() {
    final id = _lastRecordId;
    if (id == null) return;
    final state = AppScope.read(context);
    state.toggleFavorite(id);
    final nowFavorite =
        state.history.firstWhere((r) => r.id == id).isFavorite;
    _toast(nowFavorite ? 'Saved to favorites' : 'Removed from favorites');
  }

  Future<void> _pickLanguage({required bool isSource}) async {
    final state = AppScope.read(context);
    final code = await showLanguagePicker(
      context,
      selectedCode: isSource ? state.sourceLang : state.targetLang,
      title: isSource ? 'Translate from' : 'Translate to',
    );
    if (code == null) return;
    isSource ? state.setSourceLang(code) : state.setTargetLang(code);
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
            onSwap: state.swapLanguages,
            onNotifications: () => _toast('No new notifications'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl,
              ),
              children: [
                _InputCard(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  langCode: state.sourceLang,
                  maxChars: _maxChars,
                  onClear: _clear,
                  onVoice: () => _toast('Voice input needs Speech-to-Text'),
                  onCamera: () => _toast('Camera OCR needs Cloud Vision'),
                ),
                const SizedBox(height: AppSpacing.md),

                FilledButton.icon(
                  key: const ValueKey('translate-button'),
                  onPressed: _inputController.text.trim().isEmpty ||
                          _isTranslating
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

                if (_result != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ResultCard(
                    result: _result!,
                    langCode: state.targetLang,
                    isFavorite: _lastRecordId != null &&
                        state.history
                            .any((r) => r.id == _lastRecordId && r.isFavorite),
                    onCopy: _copyResult,
                    onSpeak: () => _toast('Playback needs Text-to-Speech'),
                    onFavorite: _toggleFavorite,
                    onShare: () => _toast('Sharing is not wired up yet'),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                Text('Other ways to translate',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _QuickActions(onTap: _toast),
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
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.g_translate_rounded,
                      color: Colors.white, size: 26),
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
    required this.result,
    required this.langCode,
    required this.isFavorite,
    required this.onCopy,
    required this.onSpeak,
    required this.onFavorite,
    required this.onShare,
  });

  final TranslationResult result;
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
                    horizontal: 8, vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'AI translated',
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
              result.text,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (result.isDemo) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Demo output — this phrase is not in the offline '
                      'phrasebook. Connect the Translation API for live results.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

// ------------------------------------------------------------ quick actions

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});
  final void Function(String message) onTap;

  static const _items = [
    (
      icon: Icons.record_voice_over_rounded,
      title: 'Voice',
      subtitle: 'Speak to translate',
      message: 'Voice translation needs Speech-to-Text',
    ),
    (
      icon: Icons.document_scanner_rounded,
      title: 'Camera',
      subtitle: 'Scan printed text',
      message: 'Camera OCR needs Cloud Vision',
    ),
    (
      icon: Icons.forum_rounded,
      title: 'Conversation',
      subtitle: 'Two-way chat',
      message: 'Conversation mode is coming next',
    ),
    (
      icon: Icons.smart_toy_rounded,
      title: 'AI Tutor',
      subtitle: 'Practice a language',
      message: 'AI assistant needs the Gemini API',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
        for (final item in _items)
          _QuickActionTile(
            icon: item.icon,
            title: item.title,
            subtitle: item.subtitle,
            onTap: () => onTap(item.message),
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
