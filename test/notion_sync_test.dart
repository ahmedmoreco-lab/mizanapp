import 'package:ahmed_os/data/notion_sync.dart';
import 'package:ahmed_os/models/enums.dart';
import 'package:ahmed_os/models/pillar.dart';
import 'package:ahmed_os/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

Task _notion(
  String hex16, {
  String title = 'A task',
  bool done = false,
  Pillar? pillar,
  Priority? priority,
  DateTime? due,
  String notes = '',
  DateTime? created,
  DateTime? completed,
}) =>
    Task(
      id: 'task-$hex16',
      title: title,
      pillar: pillar,
      done: done,
      priority: priority,
      dueDate: due,
      notes: notes,
      createdAt: created ?? DateTime(2026, 8, 30),
      completedAt: completed,
    );

Task _captured(String id, {String title = 'Captured here'}) => Task(
      id: id,
      title: title,
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  group('id derivation', () {
    test('a page id becomes a task id, however it is spelled', () {
      const expected = 'task-3bb3c2c549878168';
      expect(notionTaskId('3bb3c2c549878168b31bf53e0c1baaa0'), expected);
      expect(notionTaskId('3bb3c2c5-4987-8168-b31b-f53e0c1baaa0'), expected);
      expect(
        notionTaskId('https://app.notion.com/p/3bb3c2c549878168b31bf53e0c1baaa0'),
        expected,
      );
    });

    test('ownership is readable from the id alone', () {
      expect(isNotionOwned('task-3bb3c2c549878168'), isTrue);
      expect(isNotionOwned('9f8e7d6c-1234-4abc-8def-000000000000'), isFalse);
    });
  });

  group('merging', () {
    test('a task that is new in Notion is added', () {
      final result = mergeNotionTasks(
        existing: [_notion('aaaaaaaaaaaaaaaa')],
        incoming: [
          _notion('aaaaaaaaaaaaaaaa'),
          _notion('bbbbbbbbbbbbbbbb', title: 'Get a haircut'),
        ],
      );

      expect(result.added, 1);
      expect(result.tasks, hasLength(2));
      expect(result.tasks.last.title, 'Get a haircut');
    });

    test('Notion owns the content of its own tasks', () {
      final result = mergeNotionTasks(
        existing: [_notion('aaaaaaaaaaaaaaaa', title: 'Old title')],
        incoming: [
          _notion('aaaaaaaaaaaaaaaa',
              title: 'New title',
              pillar: Pillar.work,
              priority: Priority.high,
              notes: 'Updated in Notion'),
        ],
      );

      expect(result.updated, 1);
      final task = result.tasks.single;
      expect(task.title, 'New title');
      expect(task.pillar, Pillar.work);
      expect(task.priority, Priority.high);
      expect(task.notes, 'Updated in Notion');
    });

    test('ticking it off here survives a sync that still says not done', () {
      final completed = DateTime(2026, 9, 5, 14, 30);
      final result = mergeNotionTasks(
        existing: [
          _notion('aaaaaaaaaaaaaaaa', done: true, completed: completed),
        ],
        incoming: [_notion('aaaaaaaaaaaaaaaa', done: false)],
      );

      final task = result.tasks.single;
      expect(task.done, isTrue, reason: 'done is sticky');
      expect(task.completedAt, completed,
          reason: 'the original completion time is not moved');
    });

    test('finishing it in Notion marks it done here', () {
      final result = mergeNotionTasks(
        existing: [_notion('aaaaaaaaaaaaaaaa', done: false)],
        incoming: [_notion('aaaaaaaaaaaaaaaa', done: true)],
      );

      final task = result.tasks.single;
      expect(task.done, isTrue);
      expect(task.completedAt, isNotNull);
    });

    test('a task captured in the app is never touched', () {
      final mine = _captured('9f8e7d6c-1234-4abc-8def-000000000000');
      final result = mergeNotionTasks(
        existing: [mine],
        incoming: [_notion('aaaaaaaaaaaaaaaa')],
      );

      expect(result.appOnly, 1);
      expect(result.added, 1);
      expect(result.tasks.first.id, mine.id);
      expect(result.tasks.first.title, mine.title);
    });

    test('a task missing from the payload is kept, not deleted', () {
      final result = mergeNotionTasks(
        existing: [
          _notion('aaaaaaaaaaaaaaaa', title: 'Still here'),
          _notion('bbbbbbbbbbbbbbbb'),
        ],
        incoming: [_notion('bbbbbbbbbbbbbbbb')],
      );

      expect(result.tasks, hasLength(2));
      expect(result.missingFromNotion, 1);
      expect(result.tasks.first.title, 'Still here');
    });

    test('a payload without goals does not unfile a task from its goal', () {
      final filed = Task(
        id: 'task-aaaaaaaaaaaaaaaa',
        title: 'Filed under a goal',
        goalId: 'goal-ibm-bob',
        createdAt: DateTime(2026, 8, 30),
      );
      final result = mergeNotionTasks(
        existing: [filed],
        incoming: [_notion('aaaaaaaaaaaaaaaa', title: 'Retitled in Notion')],
      );

      final task = result.tasks.single;
      expect(task.title, 'Retitled in Notion');
      expect(task.goalId, 'goal-ibm-bob');
    });

    test('the date the app first saw a task is not rewritten', () {
      final firstSeen = DateTime(2026, 8, 30);
      final result = mergeNotionTasks(
        existing: [_notion('aaaaaaaaaaaaaaaa', created: firstSeen)],
        incoming: [
          _notion('aaaaaaaaaaaaaaaa',
              title: 'Edited', created: DateTime(2026, 9, 6)),
        ],
      );

      expect(result.tasks.single.createdAt, firstSeen);
    });

    test('syncing the same export twice changes nothing the second time', () {
      final incoming = [_notion('aaaaaaaaaaaaaaaa', title: 'Steady')];
      final first = mergeNotionTasks(existing: const [], incoming: incoming);
      final second =
          mergeNotionTasks(existing: first.tasks, incoming: incoming);

      expect(second.added, 0);
      expect(second.updated, 0);
      expect(second.unchanged, 1);
      expect(second.changedAnything, isFalse);
    });
  });

  group('reading a payload', () {
    test('it accepts the bundled snapshot shape', () {
      final tasks = parseNotionTasks('''
        {"tasks":[{"id":"task-aaaaaaaaaaaaaaaa","title":"From Notion",
                   "created_at":1788000000000}]}
      ''');
      expect(tasks.single.title, 'From Notion');
    });

    test('it accepts a bare list', () {
      final tasks = parseNotionTasks(
          '[{"id":"task-aaaaaaaaaaaaaaaa","title":"Bare","created_at":1788000000000}]');
      expect(tasks.single.title, 'Bare');
    });

    test('it refuses what it cannot read', () {
      expect(() => parseNotionTasks(''), throwsFormatException);
      expect(() => parseNotionTasks('not json'), throwsFormatException);
      expect(() => parseNotionTasks('{"goals":[]}'), throwsFormatException);
    });
  });
}
