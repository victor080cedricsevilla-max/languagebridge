import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/language_picker.dart';
import 'auth/login_screen.dart';

/// Profile and settings.
///
/// Every toggle writes to [AppState] only — nothing is persisted. Wiring
/// Firestore would mean replacing the setter calls, not the layout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfileHeader(
            name: user?.name ?? 'Guest',
            email: user?.email ?? 'Not signed in',
            initials: user?.initials ?? '?',
            memberSince: user?.memberSince,
            onEdit: () => _editProfile(context, state),
          ),
          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: '${state.history.length}',
                    label: 'Translations',
                    icon: Icons.translate_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    value: '${state.favorites.length}',
                    label: 'Favorites',
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatTile(
                    value: '${state.languagesUsed}',
                    label: 'Languages',
                    icon: Icons.public_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Section(
            title: 'Translation',
            children: [
              _SettingTile(
                icon: Icons.input_rounded,
                title: 'Default source language',
                trailingText: languageByCode(state.sourceLang).name,
                onTap: () async {
                  final code = await showLanguagePicker(
                    context,
                    selectedCode: state.sourceLang,
                    title: 'Default source language',
                  );
                  if (code != null) state.setSourceLang(code);
                },
              ),
              _SettingTile(
                icon: Icons.output_rounded,
                title: 'Default target language',
                trailingText: languageByCode(state.targetLang).name,
                onTap: () async {
                  final code = await showLanguagePicker(
                    context,
                    selectedCode: state.targetLang,
                    title: 'Default target language',
                  );
                  if (code != null) state.setTargetLang(code);
                },
              ),
              _SwitchTile(
                icon: Icons.auto_fix_high_rounded,
                title: 'Auto-detect language',
                subtitle: 'Identify the source language automatically',
                value: state.autoDetectEnabled,
                onChanged: state.setAutoDetectEnabled,
              ),
              _SwitchTile(
                icon: Icons.cloud_off_rounded,
                title: 'Offline phrasebook',
                subtitle: 'Keep common phrases available without data',
                value: state.offlineModeEnabled,
                onChanged: state.setOfflineModeEnabled,
              ),
            ],
          ),

          _Section(
            title: 'App',
            children: [
              _SettingTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                trailingText: _themeLabel(state.themeMode),
                onTap: () => _pickTheme(context, state),
              ),
              _SwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Push notifications',
                subtitle: 'Daily phrases and practice reminders',
                value: state.notificationsEnabled,
                onChanged: state.setNotificationsEnabled,
              ),
            ],
          ),

          _Section(
            title: 'About',
            children: [
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About Language Bridge',
                onTap: () => _showAbout(context),
              ),
              _SettingTile(
                icon: Icons.shield_outlined,
                title: 'Privacy policy',
                onTap: () => _toast(context, 'Privacy policy coming soon'),
              ),
              _SettingTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & support',
                onTap: () => _toast(context, 'Support is not wired up yet'),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md,
            ),
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, state),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out'),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Text(
                'Language Bridge · v1.0.0 (prototype)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickTheme(BuildContext context, AppState state) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                onTap: () => Navigator.pop(context, mode),
                leading: Icon(switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                }),
                title: Text(_themeLabel(mode)),
                trailing: state.themeMode == mode
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brand,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
    if (selected != null) state.setThemeMode(selected);
  }

  Future<void> _editProfile(BuildContext context, AppState state) async {
    final nameController = TextEditingController(text: state.user?.name ?? '');
    final emailController =
        TextEditingController(text: state.user?.email ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Email is required';
                  final ok = RegExp(r'^[\w.\-+]+@([\w-]+\.)+[\w-]{2,}$')
                      .hasMatch(value);
                  return ok ? null : 'Enter a valid email';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      state.updateProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );
    }
    nameController.dispose();
    emailController.dispose();
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Language Bridge',
      applicationVersion: '1.0.0 (UI prototype)',
      applicationIcon: const Icon(
        Icons.g_translate_rounded,
        size: 40,
        color: AppColors.brand,
      ),
      children: const [
        SizedBox(height: AppSpacing.sm),
        Text(
          'Real-time multilingual communication and translation for text, '
          'voice, and images.\n\n'
          'This build is a UI/UX prototype — translation, authentication and '
          'storage are mocked locally.',
          style: TextStyle(height: 1.45),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    state.signOut();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// ------------------------------------------------------------------ header

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initials,
    required this.memberSince,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String initials;
  final DateTime? memberSince;
  final VoidCallback onEdit;

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
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.white,
                    tooltip: 'Edit profile',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              if (memberSince != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Member since ${DateFormats.longDate(memberSince!)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- stat tiles

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sections

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
