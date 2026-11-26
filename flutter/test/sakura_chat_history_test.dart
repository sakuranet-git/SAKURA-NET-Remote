import 'dart:io';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:flutter_hbb/models/local_chat_history.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

class _Peer extends Fake implements FFI {
  @override
  final UuidValue sessionId = UuidValue('00000000-0000-4000-8000-000000000001');
}

class _Wire extends Fake implements RustdeskImpl {
  final sent = <String>[];
  @override
  String translate(
          {required String name, required String locale, dynamic hint}) =>
      name;
  @override
  Future<void> sessionSendChat(
      {required UuidValue sessionId,
      required String text,
      dynamic hint}) async {
    sent.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() {
    root = Directory.systemTemp.createTempSync('sakura-synthetic-chat-');
  });
  tearDown(() {
    root.deleteSync(recursive: true);
  });
  test('30 day cutoff, two independent instances, directions and deletion', () {
    var now = DateTime.utc(2026, 1, 1);
    final store = LocalChatHistory(root, clock: () => now);
    final other = LocalChatHistory(root, clock: () => now);
    store.append(
        '../synthetic-peer', true, true, now.millisecondsSinceEpoch, '古い');
    now = now.add(const Duration(seconds: 1));
    store.append(
        '../synthetic-peer', true, true, now.millisecondsSinceEpoch, '重複\n🌸');
    other.append(
        '../synthetic-peer', true, false, now.millisecondsSinceEpoch, '重複\n🌸');
    other.append('../synthetic-peer', false, true, now.millisecondsSinceEpoch,
        'separate');
    now = now.add(const Duration(days: 30) - const Duration(seconds: 1));
    store.prune();
    expect(other.read('../synthetic-peer', true).map((r) => r['mine']), [0, 1]);
    other.clear('../synthetic-peer', true);
    expect(store.read('../synthetic-peer', true), isEmpty);
    expect(store.read('../synthetic-peer', false).single['body'], 'separate');
    now = now.add(const Duration(seconds: 2));
    expect(store.read('../synthetic-peer', false), isEmpty);
    store.append('a', false, true, now.millisecondsSinceEpoch, 'first');
    other.append('b', true, false, now.millisecondsSinceEpoch, 'second');
    store.clearAll();
    expect(other.read('a', false), isEmpty);
    expect(other.read('b', true), isEmpty);
  });
  test(
      'actual chat model restores both directions of text after recreation and forgets deleted conversation',
      () {
    final peer = _Peer();
    final wire = _Wire();
    platformFFI.setBindingForTesting(wire);
    ChatModel model() =>
        ChatModel(WeakReference<FFI>(peer), history: LocalChatHistory(root));
    final key = MessageKey('synthetic-peer', ChatModel.clientModeID);
    final first = model();
    first.updateConnIdOfKey(key);
    first.send(
        ChatMessage(text: '送信🌸', user: first.me, createdAt: DateTime.now()));
    first.insertMessage(
        key,
        ChatMessage(
            text: '受信',
            user: ChatUser(id: key.peerId),
            createdAt: DateTime.now()));
    expect(wire.sent, ['送信🌸']);
    first.dispose();
    final restored = model();
    restored.updateConnIdOfKey(key);
    final msgs = restored.messages[key]!.chatMessages;
    expect(msgs.map((m) => m.text), ['受信', '送信🌸']);
    expect(msgs.last.user.id, restored.me.id);
    expect(restored.clearLocalHistory(key), isTrue);
    restored.dispose();
    final fresh = model();
    fresh.updateConnIdOfKey(key);
    expect(fresh.messages[key]!.chatMessages, isEmpty);
    fresh.dispose();
  });
}
