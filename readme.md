
# NovaFinder
macのspotlightは使いずらい！！！！！！fk

# 機能
- **/ + ⌥**にて入力ボックスを表示します。
- **検索したいワード** <デフォルトのブラウザで検索します>
- **/shell** <ターミナルを開きます>
- **/open** <finderを開きます>
- **/calc** <簡単な計算ができます> usage: `/calc 1+1`

# 設定ファイル

`~/.novafinder/settings.json` で各種設定を管理します。アプリ起動時に読み込まれます。

```json
{
  "searchEngine": "https://www.google.com/search?q=%@",
  "maxHistory": 50,
  "hotkey": {
    "keyCode": 44,
    "modifiers": ["option"]
  },
  "window": {
    "width": 660,
    "verticalOffsetRatio": 0.22
  },
  "customCommands": [
    {
      "prefix": "/git",
      "title": "Git Status",
      "subtitle": "git statusを実行",
      "iconName": "arrow.triangle.branch",
      "badgeText": "git",
      "command": "git status"
    }
  ]
}
```

### 設定項目

| キー | 説明 | デフォルト |
|---|---|---|
| `searchEngine` | 検索エンジンURL (`%@` がクエリに置換) | Google |
| `maxHistory` | 保持する履歴の最大件数 | 50 |
| `hotkey.keyCode` | 起動キーのCarbonキーコード (44 = `/`) | 44 |
| `hotkey.modifiers` | 修飾キー (`option`, `command`, `shift`, `control`) | `["option"]` |
| `window.width` | ウィンドウ幅 (px) | 660 |
| `window.verticalOffsetRatio` | 上端からの位置比率 (0.0〜1.0) | 0.22 |
| `customCommands` | カスタムコマンド一覧 (後述) | `[]` |

### カスタムコマンドの設定項目

| キー | 説明 |
|---|---|
| `prefix` | コマンドのプレフィックス (例: `/git`) |
| `title` | 表示タイトル |
| `subtitle` | サブタイトル |
| `iconName` | SF Symbols のアイコン名 |
| `badgeText` | バッジに表示するテキスト |
| `command` | 実行するシェルコマンド |

# 追加予定のコマンド・機能
- **/reboot** <再起動>
- **/shutdown** <シャットダウン>
- ai連携
- windows向けも作りたい...
#

常駐で起動してた方が便利なのでspotlightをoffにし以下の設定を行いましょう!

```
設定 -> 一般 -> ログイン項目と拡張機能 -> ログイン時に開く
```
**ログイン時に開く**にてアプリを追加したら起動時に実行されます。
