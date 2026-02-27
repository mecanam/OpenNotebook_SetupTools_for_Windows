# OpenNotebook Windows 自動セットアップツール 仕様書

## 概要

Windows上で [lfnovo/open-notebook](https://github.com/lfnovo/open-notebook)（NotebookLMのOSS代替）を自動でセットアップするツールを作成する。
ユーザーがスクリプトを実行するだけで、Docker Desktopの導入からOpenNotebookの起動、ランチャーの配置まで一括で行う。

---

## 対象プロジェクト

- **リポジトリ**: https://github.com/lfnovo/open-notebook
- **概要**: Google NotebookLMのOSS代替。Docker Composeで動作する。
- **構成**: SurrealDB + OpenNotebook本体（Python/Next.js）
- **公式docker-compose.yml**: https://raw.githubusercontent.com/lfnovo/open-notebook/main/docker-compose.yml
- **アクセスURL**: http://localhost:8502
- **ライセンス**: MIT

---

## 成果物

以下の3つのファイルを作成する。

| ファイル | 役割 |
|---|---|
| `install-open-notebook.bat` | インストーラー起動用バッチファイル。PowerShellの実行ポリシーを回避して `install-open-notebook.ps1` を実行する |
| `install-open-notebook.ps1` | インストール本体のPowerShellスクリプト |
| `open-notebook-launcher.ps1` | ランチャーUI（PowerShell + WinForms）。インストール完了後に `C:\OpenNotebook` に配置される |

---

## ファイル1: install-open-notebook.bat

### 役割

ユーザーがダブルクリックするだけで `install-open-notebook.ps1` を起動できるようにするラッパー。

### 要件

- PowerShellの実行ポリシーを `-ExecutionPolicy Bypass` で回避して `install-open-notebook.ps1` を呼び出す
- 同じディレクトリにある `install-open-notebook.ps1` を実行する
- 管理者権限で再起動する処理は `.ps1` 側で行う（`.bat` は単純に `.ps1` を呼ぶだけ）

### 実装例

```bat
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0install-open-notebook.ps1"
pause
```

---

## ファイル2: install-open-notebook.ps1

### 役割

OpenNotebookのセットアップをステップごとに自動実行するメインスクリプト。

### 動作フロー

以下の順序で処理を行う。各ステップで失敗した場合は日本語のエラーメッセージを表示して停止する。

#### ステップ1: 開始メッセージ＆事前案内

- 以下のメッセージを表示する:

```
============================================
  OpenNotebook 自動セットアップツール
============================================

このツールは OpenNotebook を自動でセットアップします。

【ご注意】
Docker Desktop が未インストールの場合、自動でインストールを行います。
その場合、PCの再起動が必要になることがあります。
作業中のファイルがあれば、事前に保存してください。

続行しますか？ (Y/N):
```

- ユーザーが `N` を入力した場合は終了する

#### ステップ2: 管理者権限チェック

- 現在のプロセスが管理者権限で実行されているか確認する
- 管理者権限がない場合、管理者権限で自分自身を再起動する（UACプロンプトが表示される）

#### ステップ3: Docker Desktop チェック

- `docker --version` コマンドを実行して Docker がインストール済みか確認する
- インストール済みの場合はステップ5へスキップする

#### ステップ4: Docker Desktop 自動インストール

- Docker Desktop for Windows のインストーラーを公式サイトからダウンロードする
  - URL: `https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe`
  - ダウンロード先: `$env:TEMP\DockerDesktopInstaller.exe`
- ダウンロード中の進捗メッセージを表示する
- サイレントインストールを実行する: `Start-Process -Wait -FilePath "$env:TEMP\DockerDesktopInstaller.exe" -ArgumentList "install", "--quiet", "--accept-license"`
- インストール完了後、再起動が必要な場合がある旨を表示し、再起動を促す:

```
Docker Desktop のインストールが完了しました。
PCを再起動する必要がある場合があります。

再起動後、もう一度このスクリプトを実行してください。
今すぐPCを再起動しますか？ (Y/N):
```

- `Y` の場合は `Restart-Computer` を実行
- `N` の場合は「再起動後にもう一度実行してください」と表示して終了

#### ステップ5: Docker Desktop 起動チェック

- `docker info` コマンドで Docker デーモンが起動しているか確認する
- 起動していない場合:
  - Docker Desktop を起動する: `Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"`
  - 「Docker Desktop を起動中です。しばらくお待ちください...」と表示
  - 最大60秒間、5秒間隔で `docker info` をリトライして起動を待つ
  - 60秒経過しても起動しない場合はエラーメッセージを表示して終了

#### ステップ6: インストール先ディレクトリ作成

- `C:\OpenNotebook` ディレクトリを作成する
- 既に存在する場合はそのまま続行する（上書きはしない）

#### ステップ7: docker-compose.yml ダウンロード

- 以下のURLから `docker-compose.yml` をダウンロードする:
  - `https://raw.githubusercontent.com/lfnovo/open-notebook/main/docker-compose.yml`
- 保存先: `C:\OpenNotebook\docker-compose.yml`
- 既にファイルが存在する場合は、上書きするか確認する

#### ステップ8: 暗号化キー自動生成＆書き込み

- 32文字のランダムな英数字文字列を生成する
- `docker-compose.yml` 内の `OPEN_NOTEBOOK_ENCRYPTION_KEY=change-me-to-a-secret-string` を生成したキーに置換する
- 既にキーが `change-me-to-a-secret-string` 以外に変更されている場合は上書きしない（ユーザーが既に設定済みと判断）

#### ステップ9: docker compose up

- カレントディレクトリを `C:\OpenNotebook` に変更する
- `docker compose up -d` を実行する
- 実行中のメッセージを表示する: 「OpenNotebook を起動中です...」
- コマンドが失敗した場合はエラーメッセージを表示して終了

#### ステップ10: ヘルスチェック

- `http://localhost:8502` に対してHTTPリクエストを送信する
- 最大120秒間、5秒間隔でリトライする
- 「サービスの起動を待機中です... (XX/120秒)」と進捗を表示する
- 120秒経過しても応答がない場合はエラーメッセージを表示して終了

#### ステップ11: ランチャー配置＆デスクトップショートカット作成

- `open-notebook-launcher.ps1` を `C:\OpenNotebook\open-notebook-launcher.ps1` にコピーする
  - もしインストーラーと同じディレクトリにランチャーファイルがない場合は、スクリプト内にランチャーのコードを埋め込んでおき、それをファイルとして書き出す
- デスクトップに「Open Notebook」というショートカット（.lnk）を作成する:
  - ターゲット: `powershell.exe`
  - 引数: `-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\OpenNotebook\open-notebook-launcher.ps1"`
  - 作業ディレクトリ: `C:\OpenNotebook`
  - アイコン: Windowsデフォルトのアイコンで可（例: `shell32.dll` のノートアイコンなど）
  - `-WindowStyle Hidden` により PowerShell のコンソールウィンドウは表示せず、WinFormsのGUIだけが表示されるようにする

#### ステップ12: ブラウザで自動オープン

- デフォルトブラウザで `http://localhost:8502` を開く: `Start-Process "http://localhost:8502"`

#### ステップ13: 完了メッセージ

```
============================================
  セットアップが完了しました！
============================================

OpenNotebook が起動しました。
ブラウザで http://localhost:8502 が開かれます。

デスクトップに「Open Notebook」ショートカットが作成されました。
次回以降はショートカットからランチャーを起動できます。

初回セットアップ:
  Settings → API Keys からAIプロバイダーのAPIキーを設定してください。
```

### エラーハンドリング方針

- 各ステップの処理は `try-catch` で囲む
- エラー発生時は「【エラー】ステップX: （具体的なエラー内容）」の形式で日本語メッセージを表示
- エラー後は処理を停止（続行しない）
- 重要な操作（Docker インストール、ファイル上書き、再起動）の前にはユーザーに確認を取る

---

## ファイル3: open-notebook-launcher.ps1

### 役割

デスクトップのショートカットから起動されるGUIランチャー。
ユーザーがOpenNotebookの起動・停止・ブラウザオープンを簡単に行えるようにする。

### UI仕様（PowerShell + WinForms）

#### ウィンドウ

- タイトル: 「Open Notebook ランチャー」
- サイズ: 幅350px × 高さ250px 程度（コンパクト）
- リサイズ不可
- 画面中央に表示

#### UI要素（上から順に配置）

1. **ステータスラベル**
   - テキスト: 「● 起動中」（緑色）または「● 停止中」（赤色）
   - フォントサイズ: 大きめ（14pt程度）
   - 中央揃え

2. **「起動」ボタン** 🟢
   - テキスト: 「▶ 起動」
   - クリック時の動作:
     1. ボタンを無効化し、テキストを「起動中...」に変更
     2. カレントディレクトリを `C:\OpenNotebook` に設定
     3. `docker compose up -d` をバックグラウンドで実行
     4. 完了後、15秒待ってからステータスを更新
     5. デフォルトブラウザで `http://localhost:8502` を開く
     6. ボタンを再度有効化

3. **「開く」ボタン** 🌐
   - テキスト: 「🌐 ブラウザで開く」
   - クリック時の動作:
     - デフォルトブラウザで `http://localhost:8502` を開く

4. **「停止」ボタン** 🔴
   - テキスト: 「■ 停止」
   - クリック時の動作:
     1. ボタンを無効化し、テキストを「停止中...」に変更
     2. カレントディレクトリを `C:\OpenNotebook` に設定
     3. `docker compose down` をバックグラウンドで実行
     4. 完了後、ステータスを更新
     5. ボタンを再度有効化

#### ステータス確認ロジック

- 起動時にステータスを確認する
- `docker compose ps` を `C:\OpenNotebook` で実行し、コンテナが起動しているか判定する
- 起動中なら「● 起動中」（緑）、停止中なら「● 停止中」（赤）を表示

#### 注意点

- Docker コマンドの実行中はUIがフリーズしないよう、バックグラウンドジョブ（`Start-Job` や `RunspacePool`）を使用する
- コマンド実行中はボタンを無効化して二重実行を防ぐ
- Docker Desktop自体が起動していない場合は「Docker Desktopが起動していません。先にDocker Desktopを起動してください。」とメッセージボックスを表示する

---

## 技術的な補足

### docker-compose.yml の内容（参考）

セットアップツールがダウンロードする公式のdocker-compose.ymlは以下の構成：

```yaml
services:
  surrealdb:
    image: surrealdb/surrealdb:v2
    command: start --log info --user root --pass root rocksdb:/mydata/mydatabase.db
    user: root
    ports:
      - "8000:8000"
    volumes:
      - ./surreal_data:/mydata
    restart: always

  open_notebook:
    image: lfnovo/open_notebook:v1-latest
    ports:
      - "8502:8502"
      - "5055:5055"
    environment:
      - OPEN_NOTEBOOK_ENCRYPTION_KEY=change-me-to-a-secret-string
      - SURREAL_URL=ws://surrealdb:8000/rpc
      - SURREAL_USER=root
      - SURREAL_PASSWORD=root
      - SURREAL_NAMESPACE=open_notebook
      - SURREAL_DATABASE=open_notebook
    volumes:
      - ./notebook_data:/app/data
    depends_on:
      - surrealdb
    restart: always
```

### 動作環境

- OS: Windows 10 / 11
- 前提: インターネット接続あり
- PowerShell: 5.1以上（Windows標準搭載）
- .NET Framework: WinFormsに必要（Windows標準搭載）

### インストール先

- 固定パス: `C:\OpenNotebook`
- データ永続化:
  - `C:\OpenNotebook\surreal_data\` — SurrealDBのデータ
  - `C:\OpenNotebook\notebook_data\` — OpenNotebookのデータ

---

## テスト観点

以下のシナリオでテストすること:

1. **クリーンインストール**: Docker未導入の状態から全ステップを実行
2. **Docker導入済み**: Docker Desktopが既にインストール・起動済みの状態から実行
3. **Docker停止状態**: Docker Desktopがインストール済みだが停止している状態から実行
4. **再実行**: 既に `C:\OpenNotebook` が存在し、docker-compose.ymlも配置済みの状態で再実行
5. **ランチャー動作**: 起動→ブラウザで開く→停止の一連の操作
6. **エラーケース**: ネットワーク未接続、ディスク容量不足など
