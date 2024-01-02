
## Actionsの説明（CI and Deploy to Heroku）

このActionsは、主に二つのジョブ、`test` と `deploy` から構成されています。

### トリガー
- `on:`: このワークフローは、`main` ブランチへのプッシュまたはプルリクエストがある場合にトリガーされます。

### ジョブ: `test`
- `runs-on: ubuntu-latest`: 最新のUbuntuランナーで実行されます。
- `steps:`: ジョブのステップを定義します。
  - `uses: actions/checkout@v2`: リポジトリのコードをチェックアウトします。
  - `name: Set up Ruby`: Rubyをセットアップします。
    - `uses: ruby/setup-ruby@v1`: Rubyをセットアップするために使用されるアクションです。
    - `with:`: Rubyのバージョンを`3.2.2`に指定します。
  - `name: Install dependencies`: 依存関係をインストールします。
    - `run: bundle install`: Bundlerを使用して依存関係をインストールします。
  - `name: Run tests`: テストを実行します。
    - `run: bundle exec rspec`: RSpecを使用してテストを実行します。

### ジョブ: `deploy`
- `needs: test`: `test` ジョブが成功した後にのみ実行されます。
- `runs-on: ubuntu-latest`: こちらも最新のUbuntuランナーで実行されます。
- `if:`: `main` ブランチへのプッシュイベント時にのみ実行されます。
- `steps:`: ジョブのステップを定義します。
  - `uses: actions/checkout@v4`: リポジトリのコードをチェックアウトします（最新バージョンを使用）。
  - `name: Set up Ruby` および `name: Install dependencies`: `test` ジョブと同様のステップ。
  - `name: Deploy to Heroku`: Herokuへのデプロイを行います。
    - `uses: akhileshns/heroku-deploy@v3.12.14`: Herokuデプロイ用のアクションです。
    - `with:`: HerokuのAPIキー、アプリ名、メールアドレスを設定し、Dockerを使用しないこと、デプロイするブランチを`main`に指定します。

## テストの解説

### require 'spec_helper'とrequire 'rack/test'
---
このセクションでは、テストスクリプトが必要とする外部ファイルやライブラリを読み込んでいます。`spec_helper`は、RSpecのテストで共通して使用する設定やヘルパーメソッドを含むファイルです。`rack/test`は、RackベースのWebアプリケーションをテストするためのメソッドを提供するライブラリです。

### require_relative '../slack_reaction_handler.rb'
---
`require_relative`は、現在のファイルの相対パスを基に別のファイルを読み込むメソッドです。ここでは、`slack_reaction_handler.rb`というファイルを読み込んでおり、このファイルにはSlackのリアクションイベントを処理するためのロジックが含まれています。

### describe 'Slack Events API'
---
このブロックでは、'Slack Events API'に関連するテストをグループ化しています。`describe`はRSpecのメソッドで、テストの構造を定義するために使用されます。

### include Rack::Test::Methods
---
`include Rack::Test::Methods`は、Rack::Testのメソッドを現在のRSpecのコンテキストに含めることを意味します。これにより、RackアプリケーションのHTTPリクエストを模倣するためのメソッドが使えるようになります。

### def app
---
`app`メソッドは、テスト対象のRackアプリケーションを返すために使用されます。ここでは`Sinatra::Application`を返しています。

### beforeブロック
---
`before`ブロックは、各テストが実行される前に実行されるコードを定義します。この例では、Notion APIの呼び出しをモック化しています。モック化とは、外部のAPIやサービスの代わりにテスト用のオブジェクトやデータを使用することです。

### context 'POST /slack/events'
---
この`context`ブロックは、HTTP POSTリクエストが`/slack/events`エンドポイントに送信された時の挙動をテストします。`context`は、特定の条件や状況下でのテストケースをグループ化するために使われます。

### responds to URL verification challenge（URL検証のチャレンジに応答するテスト）
---
**目的**

Slackから送信されるURL検証リクエストに対して正しく応答するかどうかをテストします。

**処理内容**

SlackがイベントAPIのエンドポイントを検証するために送信する`url_verification`タイプのリクエストに、`challenge`パラメーターをそのまま返すことで応答します。

**検証ポイント**
- レスポンスが成功（ステータスコード200）であること。
- レスポンスボディが`challenge`パラメーターと同じ値であること。

### triggers post_to_notion on valid reaction（有効なイベントコールバックに基づいてNotionへの投稿をトリガーするテスト）
---
**目的**

Slackのリアクションイベント（例えば`reaction_added`）が発生したときに、Notionへの投稿が適切にトリガーされるかどうかをテストします。

**処理内容**

`event_callback`タイプのリクエストを受け取り、特定のリアクションイベント（この例では`thumbs_up`）が含まれている場合、Notionへの投稿処理を呼び出します。

**検証ポイント**

- `post_to_notion`メソッドが正確に一度呼び出されること。
- レスポンスが成功（ステータスコード200）であること。

### fetches messages and triggers post_to_notion with combined text（メッセージアイテムを含む有効なイベントコールバックのテスト）
---

**目的**

リアクションが追加された特定のメッセージに関する情報を取得し、それを元にNotionへの投稿が行われるかどうかをテストします。

**処理内容**

`event_callback`タイプのリクエストに含まれるメッセージアイテム（`item`）の情報を使用して、関連するメッセージの内容を取得し、その内容を元にNotionへの投稿を行います。

**検証ポイント**
- `fetch_all_replies`メソッドが適切なパラメーターで呼び出されること。
- 取得したメッセージの内容を元に`post_to_notion`が呼び出されること。
- レスポンスが成功（ステータスコード200）であること。

### with invalid JSON（不正なJSONフォーマットに対するテスト）
---

**目的**

不正なJSONフォーマットのリクエストが送信された場合に適切にエラー処理が行われるかどうかをテストします。

**処理内容**

不正なJSONフォーマットのリクエストを受け取った場合、400エラー（Bad Request）を返します。

**検証ポイント**
- レスポンスのステータスコードが400であること。
- レスポンスボディが「Invalid JSON format」というメッセージであること。
