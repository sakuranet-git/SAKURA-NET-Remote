import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_hbb/common.dart'
    show ServerConfig, importConfig, setServerConfig;
import 'package:flutter_hbb/generated_bridge.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/mobile/widgets/dialog.dart';

class _ServerBinding extends Fake implements RustdeskImpl {
  final writes = <String, String>{};
  @override
  Future<String> mainGetApiServer({dynamic hint}) async => '';
  @override
  Future<void> mainSetOption(
      {required String key, required String value, dynamic hint}) async {
    writes[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final before = ServerConfig(
      idServer: 'old.invalid', relayServer: 'relay.invalid', key: 'synthetic');
  test('editor waits for service sync and loads role-specific values',
      () async {
    var attempts = 0;
    var reads = 0;
    final result = await readServerSettingsSnapshot(
      synced: () async => ++attempts >= 2,
      retryDelay: Duration.zero,
      read: () async {
        reads++;
        return jsonEncode(before.optionFields);
      },
    );
    expect(result.optionFields, before.optionFields);
    expect(reads, 1);
  });
  test('unsynced or invalid settings never produce an editable empty snapshot',
      () async {
    var reads = 0;
    await expectLater(
        readServerSettingsSnapshot(
          synced: () async => false,
          retryDelay: Duration.zero,
          read: () async {
            reads++;
            return '{}';
          },
        ),
        throwsA(isA<StateError>()));
    expect(reads, 0);
    for (final content in [
      'garbled',
      '[]',
      '{"key":1}',
      '{"ipc-closed":"Y"}'
    ]) {
      await expectLater(
          readServerSettingsSnapshot(
              synced: () async => true, read: () async => content),
          throwsA(anything));
    }
  });
  test('no-op, stale save, and failed reread never write options', () async {
    final wire = _ServerBinding();
    platformFFI.setBindingForTesting(wire);
    final next = ServerConfig(
        idServer: 'new.invalid',
        relayServer: before.relayServer,
        key: before.key);
    expect(
        await setServerConfig(
            null, null, ServerConfig.fromOptions(before.optionFields),
            previous: before),
        isTrue);
    expect(
        await setServerConfig(null, null, next,
            previous: before,
            readCurrent: () async =>
                ServerConfig(idServer: 'concurrent.invalid')),
        isFalse);
    expect(
        await setServerConfig(null, null, next,
            previous: before,
            readCurrent: () async => throw StateError('offline')),
        isFalse);
    expect(wire.writes, isEmpty);
  });
  test('saving one deliberate edit does not rewrite key, API, or relay',
      () async {
    final wire = _ServerBinding();
    platformFFI.setBindingForTesting(wire);
    final next = ServerConfig(
        idServer: 'new.invalid',
        relayServer: before.relayServer,
        key: before.key);
    expect(
        await setServerConfig(null, null, next,
            previous: before, readCurrent: () async => before),
        isTrue);
    expect(wire.writes, {'custom-rendezvous-server': 'new.invalid'});
  });
  test('clipboard import into the editor changes only field text', () {
    final wire = _ServerBinding();
    platformFFI.setBindingForTesting(wire);
    final fields = List.generate(4, (_) => TextEditingController());
    addTearDown(() {
      for (final field in fields) {
        field.dispose();
      }
    });
    importConfig(fields, null, before.encode(), stageOnly: true);
    expect(fields.map((c) => c.text), before.optionFields.values.toList());
    importConfig(fields, null, '{"host":"other.invalid"}', stageOnly: true);
    expect(fields.map((c) => c.text),
        ['other.invalid', before.relayServer, before.apiServer, before.key]);
    expect(wire.writes, isEmpty);
  });
  testWidgets('server settings text fields preserve literal input',
      (tester) async {
    final controller = TextEditingController(text: 'AbCdR1c1E=');
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: serverSettingsTextFormField(
          label: 'Key',
          controller: controller,
          errorMsg: '',
          autofocus: true,
        ),
      ),
    ));

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller, controller);
    expect(textField.autofocus, isTrue);
    expect(textField.keyboardType, TextInputType.visiblePassword);
    expect(textField.textCapitalization, TextCapitalization.none);
    expect(textField.autocorrect, isFalse);
    expect(textField.enableSuggestions, isFalse);
    expect(textField.smartDashesType, SmartDashesType.disabled);
    expect(textField.smartQuotesType, SmartQuotesType.disabled);
    expect(textField.enableIMEPersonalizedLearning, isFalse);
    expect(
      textField.spellCheckConfiguration,
      const SpellCheckConfiguration.disabled(),
    );
  });
}
