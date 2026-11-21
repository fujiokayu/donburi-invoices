# 脆弱性レポート（請求書情報の漏えい）

## 概要
請求書メモ欄の HTML インジェクションを起点に、PDF 生成機能を SSRF の足場にして、他組織の請求書を読み取れる状態だった。本レポートはコードレビューによる推定であり、本番ログや DB は未確認。

## 脆弱性と修正

| # | 重要度 | 場所 | 内容 | 修正 |
|---|--------|------|------|------|
| 1 | 重大 | `app/views/invoices/pdf.html.erb` | `notes` を `raw` で出力（HTML インジェクション）。`wkhtmltopdf` が iframe / script を実行・取得する | `raw` を廃止しエスケープ |
| 2 | 重大 | `app/controllers/pdf_render_controller.rb` | `Invoice.find(params[:id])` が組織で絞られず、ログイン確認もない。守りは `request.local?` のみ（IDOR） | コントローラとルートを削除 |
| 3 | 重大 | `app/services/pdf_generator.rb` | 1 と 2 の連鎖で SSRF。ループバック経由で `request.local?` と Rack::Attack の safelist を通過し、連番 ID で全組織の請求書（金額、明細、振込先口座）を取得できる。監査ログには自分の PDF 出力としか残らない | HTML を標準入力で渡し、内部 URL を取得しない。`--disable-javascript --disable-local-file-access` を追加 |
| 4 | 中 | `app/models/invoice.rb` / `invoices_controller.rb` | `bank_account_id` の所有者チェックがなく、他組織の口座情報が自分の請求書に出る（IDOR） | 同一組織の口座のみ許可するバリデーションを追加 |

## 未対応（要検討）
- 招待コードの既定値が `dev-invite`（`config/initializers/exercise_mode.rb`）。本番で `INVITE_CODE` を必須にするとビルド時の `assets:precompile` が失敗するため、`SECRET_KEY_BASE_DUMMY` を考慮した別 PR で対応する。
- `wkhtmltopdf` の外部 URL 読み込み制限（`--allow` や内部ネットワーク、`169.254.169.254` への通信遮断）。
- `Session` トークンに有効期限がなく、ログアウトやパスワード変更でも他セッションが失効しない。
- ログイン試行のスロットルが IP 単位でプロセス内メモリ。パスワード最小長は 10 文字のみ。
- 本番設定で `force_ssl = false`（ALB / CloudFront で TLS 終端）、`APP_HOST` 未設定時はホスト制限なし。
- 本アプリは訓練用の意図的な脆弱アプリ。実データの運用は避ける。

## 被害確認の手順
- `audit_logs` の `action = 'invoice.pdf'` を、ユーザー別・IP 別・短時間の大量実行で確認する。
- `invoices.notes` に `<iframe`、`<script`、`127.0.0.1`、`pdf_render` を含む行を検索する。
- アクセスログで `/pdf_render/` への連番アクセスを確認する。
- `bank_account_id` が自組織以外の口座を指す請求書を DB で突き合わせる。
- 不審アカウントの `auth_logs`、`sessions`、`organizations` の作成日時を確認する。
- 他組織の口座が設定された請求書を洗い出し、`bank_account_id` を NULL に戻す。修正後は該当請求書の更新がバリデーションエラーになるため、先に手当てする。

```sql
SELECT i.id FROM invoices i JOIN bank_accounts b ON b.id = i.bank_account_id
WHERE b.organization_id <> i.organization_id;
-- 確認後: UPDATE invoices SET bank_account_id = NULL WHERE id IN (...);
```

## 追加対応
- `SECRET_KEY_BASE`、DB パスワード、招待コードをローテーションする。
- 影響を受けた顧客へ通知し、必要に応じて警察や専門家、法務に相談する。
