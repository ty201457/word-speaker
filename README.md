# Word Speaker

一個使用 Flutter 製作的 iOS／Android 英文音標與發音 App。

## 功能

- 使用內建字庫離線查詢英文單字與 IPA 音標
- 播放美式與英式發音
- 內建約 13 萬筆北美英語發音資料
- 輸入驗證與查無單字提示
- Material 3 響應式介面

音標資料衍生自公開領域的 CMU Pronouncing Dictionary；授權資訊位於
`third_party_licenses/`。發音使用手機內建 TTS，語音包下載後可完全離線使用。

## 第一次執行

1. 安裝 [Flutter SDK](https://docs.flutter.dev/get-started/install)。
2. 解壓縮本專案並在終端機進入資料夾。
3. macOS／Linux 執行：

   ```bash
   chmod +x bootstrap.sh
   ./bootstrap.sh
   flutter run
   ```

   Windows PowerShell 執行：

   ```powershell
   flutter create --platforms=android,ios --org com.example --project-name word_speaker .
   flutter pub get
   flutter run
   ```

`flutter create` 只會補齊 iOS／Android 平台檔，不會覆蓋本專案的 `lib/main.dart`。

## 測試與檢查

```bash
flutter analyze
flutter test
```

## 用 GitHub 自動產生 APK

每次推送至 `main` 分支，GitHub Actions 都會自動分析、測試並建立 Release APK。
完成後到儲存庫的 **Actions → Build Android APK → Artifacts**，下載
`word-speaker-android`，解壓縮後即可取得 `app-release.apk`。

## 裝置需求

- Android：音標查詢不需要網路權限。
- iOS：需要 macOS 與 Xcode 才能編譯或安裝至 iPhone。
- 裝置若沒有安裝 `en-US` 或 `en-GB` 語音，請先在系統語音設定下載；之後發音可離線使用。
