import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/workout.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// Templates first, blank second: most sessions repeat, so repeating one
/// should take a single tap.
Future<Workout?> showStartWorkoutSheet(
  BuildContext context, {
  required WorkoutType type,
}) {
  return showModalBottomSheet<Workout>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.t.sheet,
    builder: (_) => _StartWorkoutSheet(type: type),
  );
}

class _StartWorkoutSheet extends StatelessWidget {
  const _StartWorkoutSheet({required this.type});

  final WorkoutType type;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final templates = app.templatesOfType(type);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x10, Sp.x20, Sp.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetGrabber(),
              Row(
                children: [
                  Expanded(
                    child: Text('Start a workout',
                        style: manrope(
                            size: 18, weight: 800, color: t.ink,
                            letterSpacing: -0.27)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 18, color: t.faint),
                    tooltip: 'Close',
                  ),
                ],
              ),
              if (templates.isEmpty) ...[
                const SizedBox(height: Sp.x8),
                const EmptyState(
                  title: 'No templates yet',
                  message:
                      'Build a workout, then save it as a template from its menu. Next time it starts pre-filled.',
                  height: 120,
                ),
              ] else ...[
                const SectionLabel('From a template', top: Sp.x14),
                for (final template in templates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.x10),
                    child: _TemplateRow(template: template),
                  ),
              ],
              const SectionLabel('Or'),
              GhostButton(
                'Empty workout',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final app = context.read<AppState>();
                  final navigator = Navigator.of(context);
                  final created = await app.startBlankWorkout(type);
                  navigator.pop(created);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template});

  final Workout template;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;

    final names = template.exercises
        .map((e) => app.exerciseName(e.exerciseId))
        .toList();
    final lastRun = app.workouts
        .where((w) => w.templateId == template.id && w.date != null)
        .fold<DateTime?>(null, (best, w) {
      if (best == null || w.date!.isAfter(best)) return w.date;
      return best;
    });

    return AppCard(
      padding: const EdgeInsets.fromLTRB(Sp.x14, Sp.x10, Sp.x6, Sp.x10),
      onTap: () async {
        final state = context.read<AppState>();
        final navigator = Navigator.of(context);
        final created = await state.startFromTemplate(template.id);
        navigator.pop(created);
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.title,
                    style: manrope(size: 15, weight: 700, color: t.ink)),
                const SizedBox(height: 1),
                Text(
                  names.isEmpty ? 'No exercises yet' : names.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta.copyWith(color: t.muted),
                ),
              ],
            ),
          ),
          if (lastRun != null)
            Padding(
              padding: const EdgeInsets.only(left: Sp.x8),
              child: Text('last ${DateFormat('d MMM').format(lastRun)}',
                  style: manrope(
                      size: 11.5, weight: 600, color: t.faint, tabular: true)),
            ),
          // Templates are managed where you meet them, not in settings.
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: t.faint),
            tooltip: 'Template options',
            onSelected: (value) => _onMenu(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete template')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    final app = context.read<AppState>();
    if (value == 'rename') {
      final name = await promptForText(
        context,
        title: 'Rename template',
        initial: template.title,
      );
      if (name != null && name.trim().isNotEmpty) {
        await app.renameTemplate(template.id, name);
      }
    } else if (value == 'delete') {
      await app.deleteWorkout(template.id);
    }
  }
}

/// Small single-field prompt used for renames.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
