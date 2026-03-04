# OpenNotebook Windows 自動セットアップツール

[OpenNotebook](https://github.com/lfnovo/open-notebook)（Google NotebookLM の OSS 代替）を Windows 上にワンクリックでセットアップするツールです。
> ## ⚠️絶対に読むこと
> * このセットアップツールは **自作** です。  
> * 一応、動作確認はしていますが、**完全な動作を保証するものではありません**  
> * 設定ファイル(ymlファイル)などを勝手に書き換えると動作しなくなる場合があります。
> * このツールによってパソコンやデータの破損などが起きた場合、当方は責任を負いかねますのでご注意ください。  
>### これがよめないひとにはきけんなので、おかえりください

## もくじ
 * [機能](#機能)
 * [動作環境](#動作環境)
 * [インストール手順](#インストール手順-わからない人はこちらを見て下さい)
 * [インストール手順(わかりやすい)](#インストール手順-わかりやすい)
 * [日常の使い方](#日常の使い方)
 * [Ollama（ローカル LLM）を使う場合](#ollamaローカル-llmを使う場合)
 * [ファイル構成](#ファイル構成)
 * [自動ツールが行うセットアップの流れ（詳細）](#自動ツールが行うセットアップの流れ詳細)
 * [データの保存場所](#データの保存場所)
 * [アンインストール](#アンインストール)
 * [Author](#author)
 * [ライセンス](#license)

## 機能

- Docker Desktop の自動インストール（未導入の場合）
- OpenNotebook の Docker Compose 環境を自動構築
- 暗号化キーの自動生成
- デスクトップショートカット＆GUI ランチャーの自動配置
- Ollama（ローカル LLM）のセットアップガイド表示

## 動作環境

- **OS**: Windows 10 / 11
- **PowerShell**: 5.1 以上（Windows標準搭載）
- **インターネット接続**: 必須（Docker・イメージのダウンロードに使用）

---
## インストール手順 (わからない人は[こちらを見て下さい](#インストール手順-わかりやすい))
PowerShellでインストーラーを保存したいディレクトリに移動し、以下のコマンドを入力してください。
```
git clone https://github.com/mecanam/OpenNotebook_SetupTools_for_Windows.git
```
## インストール手順 (わかりやすい)

### ステップ 1: ファイルをダウンロードする

1. このページ上部の緑色の **「Code」** ボタンをクリック
2. **「Download ZIP」** をクリック  
3. ダウンロードした ZIP ファイルを右クリック → **「すべて展開」** で任意のフォルダに展開

> 展開先はどこでも構いません（例: デスクトップ、ドキュメントなど）。
> OpenNotebook 本体は `C:\OpenNotebook` に自動で配置されます。

### ステップ 2: セットアップを実行する

1. 展開したフォルダを開く
2. **`install-open-notebook.bat`** をダブルクリック

   > 「WindowsによってPCが保護されました」と表示された場合:
   > **「詳細情報」** → **「実行」** をクリックしてください。

3. 「続行しますか？ (Y/N)」と聞かれたら **`Y`** を入力して Enter
4. 「このアプリがデバイスに変更を加えることを許可しますか？」と表示されたら **「はい」** をクリック

あとは自動でセットアップが進みます。完了するとブラウザで OpenNotebook が開きます。

### ステップ 3: Docker Desktop が未インストールの場合

Docker Desktop が入っていない場合、自動でインストールされます。

1. 「今すぐPCを再起動しますか？」と聞かれたら **`Y`** を入力して Enter
2. PC が再起動したら、もう一度 **`install-open-notebook.bat`** をダブルクリック
3. その後、設定の続きが実行されます
> 2回目の実行では Docker のインストールはスキップされ、OpenNotebook のセットアップのみ行われます。  
> OpenNotebook起動後、プロバイダ(OpenAIなど)とモデルのAPIなどを設定してください。

> ## AIをローカルで実行したい場合
> Ollamaが必要になります。インストール手順は[こちら](#1-ollama-をインストール)に記載しています。
---

## 日常の使い方
セットアップ完了後にデスクトップに自動的に**OpenNotebookランチャー**(自作)が作成されます。  
ランチャーを使用すれば起動コマンドなどを手動で入力する必要はありません。

### ランチャーの使い方

| 順番 | ボタン | 操作内容 |
|:----:|--------|----------|
| 1 | 🐳 Docker Desktop を起動 | まずこれを押して Docker を起動します（初回のみ必要） |
| 2 | ▶ 起動 | OpenNotebook を起動してブラウザで開きます |
| 3 | 🌐 ブラウザで開く | 既に起動中の OpenNotebook をブラウザで開き直します |
| 4 | ■ 停止 | 使い終わったらこれを押して停止します |

> **基本の流れ**: 「Docker を起動」→「起動」→ 使い終わったら「停止」

---

## Ollama（ローカル LLM）を使う場合

OpenNotebook は Ollama を使ってローカル LLM と連携できます。API キーなしで無料で利用できます。

### 1. Ollama をインストール

[https://ollama.com/download](https://ollama.com/download) からインストーラーをダウンロードして実行します。

### 2. AI モデルをダウンロード

Ollamaで使用する **AIモデルをダウンロード** します
どのモデルをダウンロードするかはパソコンのスペックと相談してください。

今回はLanguageモデルにgemma3、Embeddingモデルにmxbai-embed-largeを使用する場合のコマンドを載せておきます

インストール後、**PowerShell**（スタートメニューで「shell」と検索）を開いて以下を実行します:

```
ollama pull mxbai-embed-large
ollama pull gemma3
```
モデルをインストール後、以下のコマンドで使用できる **モデルを確認** できます
```
ollama list
```

> - `mxbai-embed-large`: 文書の検索・分析に必要なモデル（必須）
> - `gemma3`: チャットで使う AI モデル（推奨）

### 3. OpenNotebook で設定

1. Desktopに作成されたOpenNotebookランチャーを開きます。  
2. Docker Desktopを起動をクリックします。
 > すでに起動済みの場合は**起動済みのメッセージが表示されます**  
3. 起動ボタンをクリックします(数秒待つとOpenNotebookが起動します)
4. 左メニューの **Settings** をクリック
5. Modelsに移動し、以下を設定:
   - **Provider**: `Ollama`
   - **Base URL**: `http://host.docker.internal:11434`（セットアップ時に自動設定済み）
> OpenAIやClaudeのAPIを使用する場合は適切なプロバイダに移動してAPIキーを入力してください。

---

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `install-open-notebook.bat` | セットアップ起動用（ダブルクリックで実行） |
| `install-open-notebook.ps1` | セットアップ本体（自動インストーラー） |
| `open-notebook-launcher.ps1` | GUI ランチャー |

## 自動ツールが行うセットアップの流れ（詳細）

1. 開始メッセージ＆事前案内
2. 管理者権限チェック（UAC 昇格）
3. Docker Desktop の検出
4. Docker Desktop の自動インストール（未導入の場合）
5. Docker Desktop の起動確認
6. インストール先ディレクトリ作成（`C:\OpenNotebook`）
7. `docker-compose.yml` のダウンロード
8. 暗号化キーの自動生成＆環境変数設定（OLLAMA_BASE_URL 含む）
9. `docker compose up -d` でコンテナ起動
10. ヘルスチェック（最大120秒待機）
11. ランチャー配置＆デスクトップショートカット作成
12. ブラウザで自動オープン
13. 完了メッセージ＆Ollama セットアップガイド

## データの保存場所

| パス | 内容 |
|------|------|
| `C:\OpenNotebook\surreal_data\` | SurrealDB のデータ |
| `C:\OpenNotebook\notebook_data\` | OpenNotebook のデータ |

## アンインストール

OpenNotebook を完全に削除するには、**PowerShell**（スタートメニューで「powershell」と検索）を開いて以下を順番に実行します:

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

Docker Desktop 自体のアンインストールは **「設定」→「アプリ」→「Docker Desktop」→「アンインストール」** から行ってください。

## Author

* Ayuma Yamanobe (X-handlename: めかなむ)
* X(Twitter) : https://x.com/Mecanam_Manuf

## License

MIT
