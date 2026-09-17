# Release notes

## v2.4.10 (2026-09-17)

- 上流新版検知時に管理リポジトリへ通知Issueを作成。
- 通知Issueに検知タグ、tracking Issue、workflow run、承認前公開禁止を明記。
- upstream-mergeの成功・失敗を管理リポジトリへIssue通知。
- upstream-watchの失敗・キャンセルも管理リポジトリへIssue通知。
- tracking Issueの重複判定をopen Issueへ限定し、失敗後の再試行を可能化。
- 上流タグをWindowsビルドへ引き渡し、ビルドの`VERSION`に反映。
- 既存の接続先・公開鍵・ビルドゲート・配布フローは変更なし。
