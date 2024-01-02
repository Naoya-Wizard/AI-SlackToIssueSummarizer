
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

