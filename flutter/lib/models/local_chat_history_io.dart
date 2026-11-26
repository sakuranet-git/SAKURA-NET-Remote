import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart' as loader;
import 'package:sqlite3/sqlite3.dart';

/// Per-OS-user, local application data only. Never part of connection settings.
class LocalChatHistory {
  final Directory directory;
  final DateTime Function() now;
  LocalChatHistory(this.directory, {DateTime Function()? clock})
      : now = clock ?? DateTime.now;

  static LocalChatHistory? desktop() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    final String? base;
    if (Platform.isWindows) {
      base = Platform.environment['LOCALAPPDATA'];
      final windows = Platform.environment['SystemRoot'];
      if (base == null || windows == null || p.isWithin(windows, base))
        return null;
    } else if (Platform.isMacOS) {
      final uid = DynamicLibrary.process()
          .lookupFunction<Uint32 Function(), int Function()>('geteuid')();
      if (uid == 0) return null;
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return null;
      base = p.join(home, 'Library', 'Application Support');
    } else {
      return null;
    }
    if (base == null || !p.isAbsolute(base)) return null;
    return LocalChatHistory(
        Directory(p.join(base, 'SAKURA-Remote', 'ChatHistory-v1')));
  }

  String get _file => p.join(directory.path, 'messages.sqlite');
  int get _cutoff =>
      now().toUtc().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
  static bool _configured = false;
  Database _open() {
    if (Platform.isWindows && !_configured) {
      final system = Platform.environment['SystemRoot'];
      if (system == null || !p.isAbsolute(system))
        throw StateError('System library path unavailable');
      loader.open.overrideFor(
          loader.OperatingSystem.windows,
          () => DynamicLibrary.open(
              p.join(system, 'System32', 'winsqlite3.dll')));
      _configured = true;
    }
    for (final path in [
      directory.path,
      _file,
      '$_file-journal',
      '$_file-wal',
      '$_file-shm'
    ]) {
      if (FileSystemEntity.typeSync(path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw StateError('Linked history location refused');
      }
    }
    directory.createSync(recursive: true);
    if (Platform.isMacOS) {
      final chmod = DynamicLibrary.process().lookupFunction<
          Int32 Function(Pointer<Utf8>, Uint16),
          int Function(Pointer<Utf8>, int)>('chmod');
      final path = directory.path.toNativeUtf8();
      try {
        if (chmod(path, 448) != 0)
          throw StateError('Cannot restrict history directory');
      } finally {
        malloc.free(path);
      }
    }
    final db = sqlite3.open(_file);
    try {
      db.execute('PRAGMA busy_timeout=150');
      db.execute('PRAGMA secure_delete=ON');
      db.execute(
          'CREATE TABLE IF NOT EXISTS messages (seq INTEGER PRIMARY KEY, peer TEXT NOT NULL, direction INTEGER NOT NULL, mine INTEGER NOT NULL, stamp INTEGER NOT NULL, body TEXT NOT NULL)');
      db.execute(
          'CREATE INDEX IF NOT EXISTS chat_peer ON messages(peer,direction,stamp)');
      db.execute('CREATE INDEX IF NOT EXISTS chat_expiry ON messages(stamp)');
      db.execute('DELETE FROM messages WHERE stamp <= ?', [_cutoff]);
      return db;
    } catch (_) {
      db.dispose();
      rethrow;
    }
  }

  void prune() {
    if (File(_file).existsSync()) _open().dispose();
  }

  List<Map<String, Object?>> read(String peer, bool outgoing) {
    if (peer.isEmpty || !File(_file).existsSync()) return [];
    final db = _open();
    try {
      return db
          .select(
              'SELECT mine,stamp,body FROM messages WHERE peer=? AND direction=? AND stamp>? ORDER BY stamp DESC,seq DESC',
              [peer, outgoing ? 1 : 0, _cutoff])
          .map((r) => Map<String, Object?>.of(r))
          .toList();
    } finally {
      db.dispose();
    }
  }

  void append(String peer, bool outgoing, bool mine, int time, String text) {
    if (peer.isEmpty || text.isEmpty || time <= _cutoff) return;
    final db = _open();
    try {
      db.execute(
          'INSERT INTO messages(peer,direction,mine,stamp,body) VALUES(?,?,?,?,?)',
          [peer, outgoing ? 1 : 0, mine ? 1 : 0, time, text]);
    } finally {
      db.dispose();
    }
  }

  void clear(String peer, bool outgoing) {
    if (peer.isEmpty || !File(_file).existsSync()) return;
    final db = _open();
    try {
      db.execute('DELETE FROM messages WHERE peer=? AND direction=?',
          [peer, outgoing ? 1 : 0]);
    } finally {
      db.dispose();
    }
  }

  void clearAll() {
    if (!File(_file).existsSync()) return;
    final db = _open();
    try {
      db.execute('DELETE FROM messages');
    } finally {
      db.dispose();
    }
  }
}
