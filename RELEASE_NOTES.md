# Release notes

## 1.5.3 verification candidate — desktop UI and local history (unreleased)

- Windows/macOS chat history is scoped to the local OS user and conversation. Messages expire after 30 days; deletion is available per conversation and in General settings for all local history. The application does not send this history to a separate server. Already-lost messages cannot be recovered.
- The ID/relay configuration dialog waits for the service options instead of presenting an editable blank form on a known read failure. No-op saves and stale reads are rejected or skipped; unrelated fields are not submitted by the dialog.
- Fixed-password mode does not request or display a temporary password; an unavailable desktop service option snapshot is not evidence that temporary-password mode is enabled. No existing password is read, reset, or distributed by this change.
- This source entry does not certify an in-place upgrade or a two-device connection. Installer-only 2.4.11 does not contain these UI changes. No product distribution is authorized by these notes.

## 1.5.3 integration candidate — local only (2026-11-26)

- Integrated upstream `95cca3f661f635b3cc85c04935fe8d96d8f432ef` on SAKURA baseline `caf07639d5846d771059c0d2d4c985817f9f60ea`. Child repository integrates `fae47e024dd83cef6aaecde0aa7d11731df11649`; its SAKURA server, public key and application name are retained.
- Kept the SAKURA core DLL name beside upstream Windows service-command handling, SAKURA update UI and guards, Japanese branding, macOS naming and approval-only DMG handling. Disabled the stock macOS update scheduler for custom clients before it can start or acquire a lock.
- Upstream workflow now configures both repositories' Git identities and distinguishes a real conflicted index from a failed merge with no unresolved entries. Remote push/build/promotion/dispatch is opt-in; the existing deployed workflow has not been changed.
- Local source checks only are not a distribution sign-off. The upstream version is not the installer's product version. No release, tag or remote branch is created by this local integration.

## macOS v2.4.9 CI candidate (2026-10-03)

- Record the exact source commit in the macOS app bundle for downstream installer provenance checks.
- Sign the bundled service before the main executable in unsigned CI artifacts.
- Keep unsigned and signed macOS builds as internal CI artifacts; publication requires an approved, trusted installer release.
- Do not publish the combined unsigned archive.
- Gate macOS CI builds on the distribution policy test.

## v2.4.10 (2026-09-17)

- 上流新版検知時に管理リポジトリへ通知Issueを作成。
- 通知Issueに検知タグ、tracking Issue、workflow run、承認前公開禁止を明記。
- upstream-mergeの成功・失敗を管理リポジトリへIssue通知。
- upstream-watchの失敗・キャンセルも管理リポジトリへIssue通知。
- tracking Issueの重複判定をopen Issueへ限定し、失敗後の再試行を可能化。
- 上流タグをWindowsビルドへ引き渡し、ビルドの`VERSION`に反映。
- 既存の接続先・公開鍵・ビルドゲート・配布フローは変更なし。
