import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../models/language_model.dart';
import '../services/module_repository.dart';
import '../widgets/state_views.dart';
import 'language_management_screen.dart';
import 'module_lesson_screen.dart';

/// Learner entry point; the existing editing tools now live on this tab.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppScope.of(context).userId;
    if (Firebase.apps.isEmpty || userId == null) {
      return const Scaffold(
        body: MessageView(
          icon: Icons.menu_book_rounded,
          title: 'Your language modules',
          message:
              'Sign in to explore lessons and save your latest assessment.',
        ),
      );
    }
    return ModuleCatalog(
      key: ValueKey(userId),
      repository: FirestoreModuleRepository(userId: userId),
    );
  }
}

class ModuleCatalog extends StatefulWidget {
  const ModuleCatalog({super.key, required this.repository});
  final ModuleRepository repository;

  @override
  State<ModuleCatalog> createState() => _ModuleCatalogState();
}

class _ModuleCatalogState extends State<ModuleCatalog> {
  late final _languages = widget.repository.watchLanguages();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module'),
        actions: [
          IconButton(
            tooltip: 'Manage languages & lessons',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LanguageManagementScreen(),
              ),
            ),
            icon: const Icon(Icons.edit_note_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF087F96), Color(0xFF075366)],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          color: Color(0xFFA5F3FC),
                          size: 30,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'A few words.\nA new connection.',
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Explore a language, learn its words, and put your understanding to the test.',
                          style: TextStyle(
                            color: Color(0xFFDAF5F8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Find a language module',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<LanguageModel>>(
              stream: _languages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const ErrorView(
                    message:
                        'Could not load modules. Check your connection and try again.',
                  );
                }
                if (!snapshot.hasData) return const LoadingView();
                final all = snapshot.data!.where((l) => l.isActive).toList();
                final languages = all
                    .where(
                      (l) => '${l.name} ${l.description}'
                          .toLowerCase()
                          .contains(_query),
                    )
                    .toList();
                if (all.isEmpty) {
                  return const MessageView(
                    icon: Icons.menu_book_outlined,
                    title: 'Lessons are on their way',
                    message:
                        'Published language modules will appear here. Use Manage languages & lessons to add learning content.',
                  );
                }
                if (languages.isEmpty) {
                  return const MessageView(
                    icon: Icons.search_off_rounded,
                    title: 'No matching modules',
                    message: 'Try another language name.',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: languages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ModuleLessonScreen(
                              language: language,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      language.description.isEmpty
                                          ? 'Words, meanings & practice'
                                          : language.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Learn • Practice • Quiz',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
