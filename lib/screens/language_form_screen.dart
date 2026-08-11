import 'package:flutter/material.dart';

import '../models/language_model.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';

/// CREATE + UPDATE form for a language.
///
/// Pass [existing] to edit (the form is prefilled and Save updates the same
/// document); pass nothing to create a new language.
class LanguageFormScreen extends StatefulWidget {
  const LanguageFormScreen({super.key, this.existing});

  final LanguageModel? existing;

  bool get isEditing => existing != null;

  @override
  State<LanguageFormScreen> createState() => _LanguageFormScreenState();
}

class _LanguageFormScreenState extends State<LanguageFormScreen> {
  final _service = LanguageService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late bool _isActive;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _imageUrlController = TextEditingController(text: existing?.imageUrl ?? '');
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving) return; // guard against a double tap
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final language = LanguageModel(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      isActive: _isActive,
      createdAt: widget.existing?.createdAt,
    );

    try {
      if (widget.isEditing) {
        await _service.updateLanguage(language);
      } else {
        await _service.createLanguage(language);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(
        context,
        widget.isEditing
            ? 'Language updated successfully'
            : 'Language created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showSnack(context, 'Save failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Language' : 'Add Language'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _FieldLabel('Language Name'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'e.g. Cebuano',
                prefixIcon: Icon(Icons.translate_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Language name is required'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Short description of this language',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            const _FieldLabel('Image URL (optional)'),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://…',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null; // optional
                final ok = Uri.tryParse(value)?.hasAbsolutePath ?? false;
                return ok ? null : 'Enter a valid URL or leave empty';
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: SwitchListTile(
                value: _isActive,
                onChanged: _isSaving
                    ? null
                    : (v) => setState(() => _isActive = v),
                title: Text('Active', style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  _isActive
                      ? 'Visible to learners'
                      : 'Hidden from learners',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Icon(
                  _isActive
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                  : Text(widget.isEditing ? 'Save Changes' : 'Save Language'),
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
