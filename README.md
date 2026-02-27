# OpenNotebook Windows 自動セットアップツール

[OpenNotebook](https://github.com/lfnovo/open-notebook)（Google NotebookLM の OSS 代替）を Windows 上にワンクリックでセットアップするツールです。

## 機能

- Docker Desktop の自動インストール（未導入の場合）
- OpenNotebook の Docker Compose 環境を自動構築
- 暗号化キーの自動生成
- デスクトップショートカット＆GUI ランチャーの自動配置
- Ollama（ローカル LLM）のセットアップガイド表示

## 動作環境

- **OS**: Windows 10 / 11
- **PowerShell**: 5.1 以上（Windows 標準搭載）
- **インターネット接続**: 必須（Docker・イメージのダウンロードに使用）

## 使い方

### 1. セットアップ

1. このリポジトリの3ファイルを任意のフォルダにダウンロード
2. `install-open-notebook.bat` をダブルクリック
3. 画面の指示に従う（管理者権限の許可が求められます）

Docker Desktop が未インストールの場合は自動でインストールされます。インストール後に PC の再起動が必要になることがあります。再起動後、もう一度 `install-open-notebook.bat` を実行してください。

### 2. 日常の使い方

セットアップ完了後は、デスクトップに作成された **「Open Notebook」ショートカット** からランチャーを起動できます。

ランチャーのボタン:

| ボタン | 機能 |
|--------|------|
| 🐳 Docker Desktop を起動 | Docker Desktop を起動し、準備完了まで待機 |
| ▶ 起動 | OpenNotebook のコンテナを起動し、ブラウザで開く |
| 🌐 ブラウザで開く | http://localhost:8502 をブラウザで開く |
| ■ 停止 | OpenNotebook のコンテナを停止 |

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `install-open-notebook.bat` | セットアップ起動用バッチファイル |
| `install-open-notebook.ps1` | セットアップ本体（13ステップの自動インストーラー） |
| `open-notebook-launcher.ps1` | GUI ランチャー（WinForms） |

## セットアップの流れ

1. 開始メッセージ＆事前案内
2. 管理者権限チェック（UAC 昇格）
3. Docker Desktop の検出
4. Docker Desktop の自動インストール（未導入の場合）
5. Docker Desktop の起動確認
6. インストール先ディレクトリ作成（`C:\OpenNotebook`）
7. `docker-compose.yml` のダウンロード
8. 暗号化キーの自動生成＆書き込み
9. `docker compose up -d` でコンテナ起動
10. ヘルスチェック（最大120秒待機）
11. ランチャー配置＆デスクトップショートカット作成
12. ブラウザで自動オープン
13. 完了メッセージ＆Ollama セットアップガイド

## Ollama（ローカル LLM）を使う場合

OpenNotebook はローカル LLM と連携できます。

1. [Ollama](https://ollama.com/download) をインストール
2. 必要なモデルをダウンロード:
   ```
   ollama pull mxbai-embed-large   # Embedding モデル（必須）
   ollama pull gemma3              # チャットモデル（推奨）
   ```
3. OpenNotebook の Settings で設定:
   - **Provider**: Ollama
   - **Base URL**: `http://host.docker.internal:11434`

## データの保存場所

| パス | 内容 |
|------|------|
| `C:\OpenNotebook\surreal_data\` | SurrealDB のデータ |
| `C:\OpenNotebook\notebook_data\` | OpenNotebook のデータ |

## アンインストール

```powershell
# コンテナとイメージを削除
docker compose -f C:\OpenNotebook\docker-compose.yml down -v
docker rmi lfnovo/open_notebook:v1-latest
docker rmi surrealdb/surrealdb:latest

# データフォルダを削除
Remove-Item -Recurse -Force C:\OpenNotebook

# デスクトップショートカットを削除
Remove-Item "$env:USERPROFILE\Desktop\Open Notebook.lnk"
```

Docker Desktop 自体のアンインストールは「設定 → アプリ → Docker Desktop」から行ってください。

## ライセンス

MIT
