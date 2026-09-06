import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../home/home_page.dart' show TaskLine;
import '../widgets/common.dart';

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

enum _Span { week, month }

/// Where a task gets a place in time. The week strip is the day-to-day
/// view; the month grid is for looking at the shape of a few weeks at
/// once, which a seven-day window cannot show you.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  _Span _span = _Span.week;
  DateTime _selected = _midnight(DateTime.now());

  /// Monday of the visible week, or the first of the visible month.
  late DateTime _anchor = _startOfWeek(_selected);

  DateTime _startOfWeek(DateTime d) =>
      _midnight(d).subtract(Duration(days: d.weekday - 1));

  void _setSpan(_Span span) {
    setState(() {
      _span = span;
      _anchor = span == _Span.week
          ? _startOfWeek(_selected)
          : DateTime(_selected.year, _selected.month);
    });
  }

  void _step(int direction) {
    setState(() {
      _anchor = _span == _Span.week
          ? _anchor.add(Duration(days: 7 * direction))
          : DateTime(_anchor.year, _anchor.month + direction);
    });
  }

  void _goToday() {
    final today = _midnight(DateTime.now());
    setState(() {
      _selected = today;
      _anchor = _span == _Span.week
          ? _startOfWeek(today)
          : DateTime(today.year, today.month);
    });
  }

  String get _rangeLabel => _span == _Span.week
      ? '${DateFormat('d MMM').format(_anchor)} – '
          '${DateFormat('d MMM').format(_anchor.add(const Duration(days: 6)))}'
      : DateFormat('MMMM y').format(_anchor);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final tasks = app.tasksOn(_selected);
    final isToday = _sameDay(_selected, DateTime.now());

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.x8, Sp.x4, Sp.x14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.chevron_left_rounded, color: t.muted),
                    tooltip: 'Back',
                  ),
                  Text('Home',
                      style: manrope(size: 14, weight: 600, color: t.muted)),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToday,
                    child: Text('Today',
                        style:
                            manrope(size: 13, weight: 700, color: t.muted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(Sp.x20, Sp.x4, Sp.x20, Sp.x24),
                children: [
                  const ScreenTitle('Calendar'),
                  const SizedBox(height: Sp.x14),
                  _SpanSegments(value: _span, onChanged: _setSpan),

                  const SizedBox(height: Sp.x20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_rangeLabel,
                            style: manrope(
                                size: 15, weight: 700, color: t.ink)),
                      ),
                      _Stepper(
                        onBack: () => _step(-1),
                        onForward: () => _step(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: Sp.x10),

                  if (_span == _Span.week)
                    _WeekStrip(
                      start: _anchor,
                      selected: _selected,
                      onSelect: (d) => setState(() => _selected = d),
                    )
                  else
                    _MonthGrid(
                      month: _anchor,
                      selected: _selected,
                      onSelect: (d) => setState(() => _selected = d),
                    ),

                  SectionLabel(
                    isToday
                        ? 'Today'
                        : DateFormat('EEEE d MMMM').format(_selected),
                  ),
                  if (tasks.isEmpty)
                    const EmptyState(
                      title: 'Nothing on this day',
                      message:
                          'Open a task from Home and give it this date to put it here.',
                      height: 120,
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x14),
                      child: Column(
                        children: [
                          for (final task in tasks) TaskLine(task: task),
                        ],
                      ),
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.onBack, required this.onForward});

  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.chevron_left_rounded, size: 20, color: t.muted),
          visualDensity: VisualDensity.compact,
          tooltip: 'Previous',
        ),
        IconButton(
          onPressed: onForward,
          icon: Icon(Icons.chevron_right_rounded, size: 20, color: t.muted),
          visualDensity: VisualDensity.compact,
          tooltip: 'Next',
        ),
      ],
    );
  }
}

/// A dot under a date means open work. Its absence means a free day —
/// which is information too, so the row keeps its height either way.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
    this.showWeekday = false,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;
  final bool dimmed;
  final bool showWeekday;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final t = context.t;
    final count = app.openCountOn(day);
    final isToday = _sameDay(day, DateTime.now());

    final Color number;
    if (selected) {
      number = t.btnInk;
    } else if (dimmed) {
      number = t.faint;
    } else {
      number = t.ink;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          if (showWeekday) ...[
            Text(DateFormat('E').format(day).substring(0, 1),
                style: manrope(size: 10, weight: 700, color: t.faint)),
            const SizedBox(height: Sp.x6),
          ],
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? t.btn : Colors.transparent,
              border: !selected && isToday
                  ? Border.all(color: t.ink, width: 1.4)
                  : null,
              borderRadius: BorderRadius.circular(Rad.chip),
            ),
            child: Text('${day.day}',
                style: manrope(
                    size: 14,
                    weight: isToday || selected ? 700 : 500,
                    color: number,
                    tabular: true)),
          ),
          const SizedBox(height: Sp.x4),
          SizedBox(
            height: 5,
            child: count == 0
                ? null
                : Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? t.ink : t.muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.start,
    required this.selected,
    required this.onSelect,
  });

  final DateTime start;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final day = start.add(Duration(days: i));
                return _DayCell(
                  day: day,
                  selected: _sameDay(day, selected),
                  showWeekday: true,
                  onTap: () => onSelect(day),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final first = DateTime(month.year, month.month);
    // Grids start on Monday, so back up to the Monday on or before the 1st.
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    final weeks =
        ((first.weekday - 1) + DateUtils.getDaysInMonth(month.year, month.month) + 6) ~/ 7;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('E')
                        .format(gridStart.add(Duration(days: i)))
                        .substring(0, 1),
                    style: manrope(size: 10, weight: 700, color: t.faint),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Sp.x6),
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = gridStart.add(Duration(days: w * 7 + d));
                      return _DayCell(
                        day: day,
                        selected: _sameDay(day, selected),
                        dimmed: day.month != month.month,
                        onTap: () => onSelect(day),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SpanSegments extends StatelessWidget {
  const _SpanSegments({required this.value, required this.onChanged});

  final _Span value;
  final ValueChanged<_Span> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const labels = {_Span.week: 'Week', _Span.month: 'Month'};

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.track,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (final span in _Span.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(span),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: span == value ? t.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(labels[span]!,
                      style: manrope(
                        size: 13.5,
                        weight: 700,
                        color: span == value ? t.ink : t.muted,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
