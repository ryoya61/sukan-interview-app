# スイカン面接評価アプリ（独立版）

Googleアカウント・Claudeアカウントとも無関係に動く、独立したWebアプリです。
面接官はログイン不要でURLを開くだけで評価を入力でき、送信すると自動で加重採点・合否判定・DISCタイプ判定が行われます。

構成:
- フロントエンド（画面）: GitHub Pages（無料）
- データ保存: Supabase（無料、Googleとは無関係の独立サービス）

ファイル構成:
- `index.html` … 面接官が使う評価入力フォーム
- `results.html` … 管理者用の結果一覧画面（パスフレーズで保護）
- `config.js` … Supabaseの接続情報を入力するファイル
- `supabase_setup.sql` … Supabase側で1回だけ実行するセットアップSQL

---

## セットアップ手順

### 1. Supabaseプロジェクトを作成する

1. https://supabase.com にアクセスし、無料アカウントを作成（GitHubアカウントでもメールアドレスでもOK）。
2. 「New project」から新しいプロジェクトを作成（プロジェクト名は任意、リージョンは Tokyo が近くて安心です）。
3. プロジェクトが起動したら、左メニューの **SQL Editor** を開き、「New query」を選択。
4. このフォルダ内の `supabase_setup.sql` の中身をすべてコピーして貼り付けます。
5. 貼り付けた内容の中にある `'YOUR_PASSPHRASE_HERE'` の部分を、結果一覧を見るときに使いたい好きな合言葉（パスフレーズ）に書き換えます（例: `'sukan2026'`）。この合言葉は人事担当者だけに共有してください。
6. 右下の「Run」ボタンで実行します。エラーが出ずに完了すれば成功です。

### 2. 接続情報を控える

1. Supabaseの左メニュー **Project Settings → API** を開きます。
2. 「Project URL」と「anon public」キーの2つをコピーします（この2つは公開されても安全な値です）。

### 3. config.js に貼り付ける

`config.js` を開き、以下のように書き換えて保存します。

```js
const SUPABASE_URL = "https://xxxxxxxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "ここにanon publicキーを貼り付け";
```

### 4. GitHub Pagesを有効化する

1. このリポジトリの **Settings → Pages** を開き、「Source」を `main` ブランチ・`/ (root)` に設定して保存します。
2. しばらくすると `https://ryoya61.github.io/sukan-interview-app/` のようなURLでアプリが公開されます。

### 5. 動作確認

1. 公開されたURL（例: `.../index.html`）を開き、テスト用のデータを1件送信してみます。
2. `.../results.html` を開き、手順1で設定した合言葉を入力して、今送信したテストデータが表示されることを確認します。
3. 確認できたら、Supabaseの **Table Editor → evaluations** からテスト行を削除しておくと綺麗です。

---

## 運用方法

- 面接官には `index.html` のURL（例: `https://ryoya61.github.io/sukan-interview-app/index.html`）を共有してください。ログイン不要でそのまま入力できます。
- 人事担当者は `results.html` のURL＋合言葉で、いつでも一覧・詳細・CSVダウンロードができます。
- 合言葉を変更したい場合は、SupabaseのSQL Editorで以下を実行してください（`supabase_setup.sql` の末尾にも記載があります）。

```sql
insert into app_secrets (key, value)
values ('admin_passphrase_hash', crypt('新しい合言葉', gen_salt('bf')))
on conflict (key) do update set value = excluded.value;
```

## セキュリティについての補足

- 面接官側（入力フォーム）は誰でも新規データを追加できますが、既存データの閲覧・変更・削除はできません。
- 結果一覧の閲覧は、Supabase側で合言葉が正しいと確認できた場合のみサーバー側でデータを返す仕組み（RPC関数）になっており、合言葉を知らない人がデータベースに直接アクセスしても中身は見えません。
- より高いセキュリティが必要な場合（例: 採用担当者ごとにログインを分けたい等）は、Supabase Authを使った本格的なログイン機能への拡張も可能です。必要であればお知らせください。
