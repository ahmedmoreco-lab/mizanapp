import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pillar.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';

/// Aspirational pillars stay taggable but sit out of the neglect
/// algorithm. Otherwise every morning opens with three pillars saying
/// they have been untouched for forty days, and you stop reading Home.
class PillarsPage extends StatelessWidget {
  const PillarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final on = app.settings.suggestingPillars;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Pillars',
            style: manrope(size: 16, weight: 700, color: t.ink)),
        iconTheme: IconThemeData(color: t.muted),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Sp.x20, Sp.x4, Sp.x20, Sp.x24),
        children: [
          Text(
            'Every pillar stays available for tagging tasks and goals. '
            'The switch decides whether Home may suggest it in the morning.',
            style: AppType.body.copyWith(color: t.muted),
          ),
          const SectionLabel('Suggest in the morning'),
          Container(
            decoration: BoxDecoration(
              color: t.card,
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(Rad.card),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < Pillar.values.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.lineSoft),
                  _PillarSwitch(
                    pillar: Pillar.values[i],
                    value: on.contains(Pillar.values[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarSwitch extends StatelessWidget {
  const _PillarSwitch({required this.pillar, required this.value});

  final Pillar pillar;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x14, vertical: Sp.x8),
      child: Row(
        children: [
          PillarBadge(pillar, size: 28),
          const SizedBox(width: Sp.x10),
          Expanded(
            child: Text(pillar.label,
                style: manrope(size: 14.5, weight: 600, color: t.ink)),
          ),
          Switch(
            value: value,
            activeTrackColor: t.pillar(pillar),
            onChanged: (v) =>
                context.read<AppState>().setPillarSuggesting(pillar, v),
          ),
        ],
      ),
    );
  }
}
