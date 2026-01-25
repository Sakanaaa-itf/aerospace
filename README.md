# AeroSpace Configuration

このディレクトリには、AeroSpaceのウィンドウマネージャー設定が含まれています。

## ファイル構成

```
.config/aerospace/
├── aerospace.toml.base          # 基本設定（GitHubで共有）
├── aerospace.toml.local         # 端末固有設定（Git管理外）
├── aerospace.toml.local.example # ローカル設定のサンプル
├── aerospace.toml               # 生成される最終設定ファイル
├── build-config.sh              # 設定ビルドスクリプト
└── README.md                    # このファイル
```

## セットアップ

### 初回セットアップ

1. サンプルファイルをコピーしてローカル設定を作成：
   ```bash
   cp ~/.config/aerospace/aerospace.toml.local.example ~/.config/aerospace/aerospace.toml.local
   ```

2. `aerospace.toml.local` を編集して、この端末固有のワークスペース割り当てを設定

3. 設定をビルド：
   ```bash
   ~/.config/aerospace/build-config.sh
   ```

### 新しい端末でのセットアップ

1. このリポジトリをクローン

2. ローカル設定を作成（サンプルファイルを参考に）：
   ```bash
   cp ~/.config/aerospace/aerospace.toml.local.example ~/.config/aerospace/aerospace.toml.local
   # エディタで編集
   ```

3. 設定をビルド：
   ```bash
   ~/.config/aerospace/build-config.sh
   ```

## 使い方

### 設定の変更

#### 基本設定（全端末共通）を変更する場合

1. `aerospace.toml.base` を編集
2. 変更をコミット＆プッシュ
3. `build-config.sh` を実行して設定を再生成

#### ワークスペース割り当て（端末固有）を変更する場合

1. `aerospace.toml.local` を編集
2. `build-config.sh` を実行して設定を再生成
3. **このファイルはコミットしない**（.gitignoreで除外済み）

### 設定の再ビルド

設定を変更したら、以下のコマンドで再ビルドします：

```bash
~/.config/aerospace/build-config.sh
```

このスクリプトは：
- `aerospace.toml.base` と `aerospace.toml.local` を結合
- `aerospace.toml` を生成
- AeroSpaceが起動中の場合は自動的に再読み込み

## ワークスペース割り当ての例

`aerospace.toml.local` の例：

```toml
# Chrome → workspace 1
[[on-window-detected]]
if.app-id = 'com.google.Chrome'
run = 'move-node-to-workspace 1'

# VS Code → workspace 2
[[on-window-detected]]
if.app-id = 'com.microsoft.VSCode'
run = 'move-node-to-workspace 2'

# Slack → workspace 5
[[on-window-detected]]
if.app-id = 'com.tinyspeck.slackmacgap'
run = 'move-node-to-workspace 5'
```

### アプリケーションIDの確認方法

```bash
# 起動中のアプリケーションのIDを確認
osascript -e 'id of app "アプリケーション名"'

# 例
osascript -e 'id of app "Google Chrome"'
# => com.google.Chrome
```

## Git管理

### コミットするファイル
- `aerospace.toml.base` - 基本設定
- `aerospace.toml.local.example` - ローカル設定のサンプル
- `build-config.sh` - ビルドスクリプト
- `README.md` - このドキュメント

### コミットしないファイル（.gitignore設定済み）
- `aerospace.toml` - 生成されるファイル
- `aerospace.toml.local` - 端末固有の設定

## トラブルシューティング

### 設定が反映されない

1. 設定をビルドし直す：
   ```bash
   ~/.config/aerospace/build-config.sh
   ```

2. AeroSpaceを手動で再起動

### ローカル設定がない状態でビルドしても問題ない？

はい、問題ありません。`aerospace.toml.local` がない場合は、基本設定のみで設定ファイルが生成されます（警告メッセージが表示されますが、エラーではありません）。
