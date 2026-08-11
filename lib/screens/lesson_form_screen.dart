import 'package:flutter/material.dart';

import '../models/lesson_model.dart';
import '../services/lesson_service.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';

/// CREATE + UPDATE form for a lesson.
///
/// Always tied to a language via [languageId]. Pass [existing] to edit (the
/// form is prefilled and Save updates the same document); pass nothing to
/// create a new lesson under the language.
class LessonFormScreen extends StatefulWidget {
  const LessonFormScreen({
    super.key,
    required this.languageId,
    this.languageName,
    this.existing,
  });

  final String languageId;
  final String? languageName;
  final Lesson? existing;

  bool get isEditing => existing != null;

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _service = LessonService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _contentController;
  late final TextEditingController _translationController;
  late final TextEditingController _pronunciationController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _contentController = TextEditingController(text: e?.content ?? '');
    _translationController = TextEditingController(text: e?.translation ?? '');
    _pronunciationController =
        TextEditingController(text: e?.pronunciation ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    _translationController.dispose();
    _pronunciationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving) return; // guard against a double tap
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final lesson = Lesson(
      id: widget.existing?.id ?? '',
      languageId: widget.languageId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      content: _contentController.text.trim(),
      translation: _translationController.text.trim(),
      pronunciation: _pronunciationController.text.trim(),
      createdAt: widget.existing?.createdAt,
      updatedAt: widget.existing?.updatedAt,
    );

    try {
      if (widget.isEditing) {
        await _service.updateLesson(lesson);
      } else {
        await _service.createLesson(lesson);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(
        context,
        widget.isEditing
            ? 'Lesson updated successfully'
            : 'Lesson created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showSnack(context, 'Save failed: $e', isError: true);
    }
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.languageName;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Lesson' : 'Add Lesson'),
        bottom: subtitle == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm,
                    ),
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _FieldLabel('Lesson Title'),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. Basic Greetings',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => _required(v, 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Category'),
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. Greetings, Numbers, Directions',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: (v) => _required(v, 'Category'),
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Description (optional)'),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What this lesson covers',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Content'),
            TextFormField(
              controller: _contentController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'The word or phrase in this language',
              ),
              validator: (v) => _required(v, 'Content'),
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Translation'),
            TextFormField(
              controller: _translationController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'The English (or target) translation',
              ),
              validator: (v) => _required(v, 'Translation'),
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Pronunciation (optional)'),
            TextFormField(
              controller: _pronunciationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. ma-a-yong bun-tag',
                prefixIcon: Icon(Icons.record_voice_over_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.isEditing ? 'Save Changes' : 'Save Lesson'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
