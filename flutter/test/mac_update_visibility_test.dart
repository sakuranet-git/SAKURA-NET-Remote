import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/desktop/widgets/mac_update_visibility.dart';

void main() {
  final manifest = <String, dynamic>{
    'platform': 'macos',
    'arch': 'arm64',
    'product_version': '2.4.9',
    'team_id': 'A9X2S694BT',
    'signature_required': true,
  };

  test('shows only a newer signed version for the installed team', () {
    expect(shouldShowMacUpdate(manifest, '2.4.8', 'A9X2S694BT'), isTrue);
    expect(shouldShowMacUpdate(manifest, '2.4.9', 'A9X2S694BT'), isFalse);
    expect(shouldShowMacUpdate(manifest, '2.5.0', 'A9X2S694BT'), isFalse);
  });

  test('never advertises an update that cannot be installed', () {
    expect(shouldShowMacUpdate(manifest, '2.4.8', ''), isFalse);
    expect(shouldShowMacUpdate(manifest, '2.4.8', 'OTHERTEAM'), isFalse);
    expect(
      shouldShowMacUpdate(
          {...manifest, 'team_id': 'UNSIGNED-DEVELOPMENT'},
          '2.4.8',
          'UNSIGNED-DEVELOPMENT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest, 'signature_required': false},
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest, 'platform': 'windows'},
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest, 'arch': 'x64'},
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest}..remove('team_id'),
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest, 'product_version': 'v2.4.9'},
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
    expect(
      shouldShowMacUpdate({...manifest, 'product_version': ''},
          '2.4.8', 'A9X2S694BT'),
      isFalse,
    );
  });

  test('compares product versions with missing zero components', () {
    expect(compareProductVersions('2.4', '2.4.0'), 0);
    expect(compareProductVersions('2.4.10', '2.4.9'), 1);
    expect(compareProductVersions('2.4.9', '2.4.10'), -1);
  });
}
