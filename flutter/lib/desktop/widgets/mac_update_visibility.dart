/// A home-screen update prompt is shown only for a newer, installable Mac build.
bool shouldShowMacUpdate(
  Map<String, dynamic> manifest,
  String installedVersion,
  String installedTeamId,
) {
  final latest = manifest['product_version']?.toString() ?? '';
  final publishedTeamId = manifest['team_id']?.toString() ?? '';
  if (manifest['platform'] != 'macos' ||
      manifest['arch'] != 'arm64' ||
      manifest['signature_required'] != true ||
      publishedTeamId.isEmpty ||
      publishedTeamId == 'UNSIGNED-DEVELOPMENT' ||
      publishedTeamId != installedTeamId ||
      !RegExp(r'^\d+(\.\d+){1,3}$').hasMatch(latest) ||
      !RegExp(r'^\d+(\.\d+){1,3}$').hasMatch(installedVersion)) {
    return false;
  }
  return compareProductVersions(latest, installedVersion) > 0;
}

int compareProductVersions(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va > vb ? 1 : -1;
  }
  return 0;
}
