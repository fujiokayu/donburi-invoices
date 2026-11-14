# Donburi 🍚

請求書管理 SaaS のデモアプリケーションです。

> **⚠️ 訓練用の意図的に脆弱なアプリです。**
> これは「インシデント対応ハンズオン」で使うための教材で、
> セキュリティ上の問題を**わざと**残してあります。実在のサービスではなく、
> 本番環境・実データで使ってはいけません。参加者が脆弱性を発見・分析するための題材です。

## できること

- 招待コード付きのサインアップ / ログイン（テナント ＝ 会社単位）
- 請求書の作成・編集・削除（明細・振込先口座つき）
- 請求書の PDF 出力
- 監査ログ・認証ログの記録

## 技術構成

- Ruby 3.3 / Rails 8 / PostgreSQL
- PDF 生成は wkhtmltopdf
- サーバサイドレンダリング（ERB）、JS ビルドなし
- デプロイ先は AWS ECS Fargate（`deploy/` の Terraform 参照）

## ローカルで動かす

### A. ネイティブ（Ruby を手元に用意できる場合）

```bash
cp .env.example .env
docker compose up -d db          # PostgreSQL だけ起動
bundle install
bin/rails db:prepare db:seed
bin/rails server
```

`http://localhost:3000` で起動します。シードのログインは
`admin@minato-seimen.example` / `donburi-demo-pw`。

> PDF 出力にはローカルに `wkhtmltopdf` が必要です。無い場合は下記 B を使ってください。

### B. フルコンテナ（Fargate と同じ本番イメージ）

```bash
bundle install                   # Gemfile.lock を生成（初回のみ）
docker compose up --build
```

本番イメージ（wkhtmltopdf 同梱）で `web` と `db` が起動します。
`http://localhost:3000`。サインアップには招待コード（既定 `dev-invite`）が必要です。

## 公開時の安全装置

招待コード・全ページの訓練バナー・`noindex`・メール送信なし・入力長制限を備えています。
常設せず、イベント期間中のみ・招待制で公開してください。詳細は [SECURITY.md](./SECURITY.md)。
