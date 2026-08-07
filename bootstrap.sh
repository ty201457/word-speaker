#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo '找不到 Flutter。請先安裝：https://docs.flutter.dev/get-started/install'
  exit 1
fi

project_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$project_dir"

flutter create --platforms=android,ios --org com.example --project-name word_speaker .
flutter pub get

echo
echo '準備完成。連接手機或開啟模擬器後執行：'
echo '  flutter run'
