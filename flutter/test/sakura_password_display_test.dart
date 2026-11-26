import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'fixed, offline, click-only, stopped or unknown never fetch or display a password',
      () async {
    for (final args in [
      (true, false, kUsePermanentPassword, 'password'),
      (false, false, kUseBothPasswords, 'password'),
      (true, false, kUseTemporaryPassword, 'click'),
      (true, true, kUseTemporaryPassword, 'password'),
      (true, false, 'invalid', 'password'),
    ]) {
      expect(
          await visibleTemporaryPassword(
              settingsReady: args.$1,
              stopped: args.$2,
              method: args.$3,
              approval: args.$4,
              read: () => throw StateError('must not read')),
          '-');
    }
  });
  test(
      'explicit temporary policy displays a synthetic value, cleared value does not linger',
      () async {
    for (final mode in [kUseTemporaryPassword, kUseBothPasswords]) {
      expect(
          await visibleTemporaryPassword(
              settingsReady: true,
              stopped: false,
              method: mode,
              approval: 'password',
              read: () async => 'TEST'),
          'TEST');
      expect(
          await visibleTemporaryPassword(
              settingsReady: true,
              stopped: false,
              method: mode,
              approval: 'password',
              read: () async => ''),
          '-');
    }
  });
}
