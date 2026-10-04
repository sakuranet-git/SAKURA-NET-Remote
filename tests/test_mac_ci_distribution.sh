#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/flutter-build.yml"

grep -Fq 'codesign --force --sign - "$APP/Contents/MacOS/service"' "$WORKFLOW"
grep -Fq 'Add :SAKURASourceCommit string ${GITHUB_SHA}' "$WORKFLOW"
grep -Fq "if: env.MACOS_P12_BASE64 != '' && env.UPLOAD_ARTIFACT == 'true'" "$WORKFLOW"
grep -Fq 'Upload signed macOS DMG for approval' "$WORKFLOW"
grep -Fq 'sakura-signed-macos-${{ matrix.job.arch }}' "$WORKFLOW"
if grep -Eq 'actions/checkout@[0-9a-f]{41}' "$WORKFLOW"; then
    echo 'actions/checkout commit must be exactly 40 hex characters.' >&2
    exit 1
fi
grep -Fq 'if: ${{ false }}' "$WORKFLOW"

if grep -Fq 'rm -rf *.dmg' "$WORKFLOW"; then
    echo 'Mac signing workflow must preserve the old DMG in trash.' >&2
    exit 1
fi
if grep -Fq 'MACOS_P12_BASE64 != null' "$WORKFLOW"; then
    echo 'Missing signing secrets must not enable macOS release steps.' >&2
    exit 1
fi

VALIDATION_WORKFLOW="$ROOT/.github/workflows/mac-validation.yml"
if [ -f "$VALIDATION_WORKFLOW" ]; then
    grep -Fq 'contents: read' "$VALIDATION_WORKFLOW"
    grep -Fq 'MACOS_P12_BASE64: ""' "$VALIDATION_WORKFLOW"
    grep -Fq 'target: aarch64-apple-darwin' "$VALIDATION_WORKFLOW"
    grep -Fq 'run: flutter test test/mac_update_visibility_test.dart' "$VALIDATION_WORKFLOW"
    if grep -Eq 'softprops/action-gh-release|gh release|target: x86_64-apple-darwin|^  push:' "$VALIDATION_WORKFLOW"; then
        echo 'Mac validation must be manual, arm64 only, and must not publish releases.' >&2
        exit 1
    fi
fi
echo 'Mac CI distribution checks passed'
