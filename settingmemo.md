- XcodeでShare ExtensionのInfo.plistに `NSExtensionActivationSupportsImageWithMaxCount` を追加していることを確認
- 本体アプリとShare ExtensionのApp Groupに `group.logsense` を追加し、Debug/Release どちらのビルド設定でも有効になっていることを確認
- Release ビルド時に必要に応じて Gyazo のアクセストークンを入力しておく
- Share Extension の Info.plist で `LSApplicationQueriesSchemes` に `logsense` を追加し、カスタム URL スキームでアプリを開けるようにする
