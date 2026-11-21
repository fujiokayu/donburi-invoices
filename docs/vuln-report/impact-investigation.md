# 影響調査レポート（請求書情報の漏えい）

脆弱性の内容と修正は `docs/vulun-report/report.md` を参照。本書は影響範囲の調査結果をまとめる。

## 結論
- 調査できたのは、CloudWatch Logs から手動でエクスポートされた 200 行（2026-11-21 07:30:39〜07:43:27 UTC、JST 16:30〜16:43、約 13 分）のみ。**全期間の調査は未完了**。
- AWS には接続できず、CloudWatch Logs や DB を直接は調べていない（認証情報なし。コンソールのパスワードは CLI / API では使えない）。
- この範囲のログで、報告済みの SSRF 攻撃が**実際に悪用された**ことを確認した。
- **誰の請求書が読まれたかは未特定**。みなと製麺だけかどうかも**判断できない**。全組織が対象になりうるものとして扱う。

## 確認できた事実
攻撃元 IP は `182.250.54.35`。

| 時刻 (UTC) | 内容 |
|---|---|
| 07:30:39 | `InvoicesController#create`。取引先名 `ssrf-probe` の請求書 ID 358 を作成。メモ欄に `http://127.0.0.1:3000/pdf_render/1`〜`/5` を読み込む `<iframe>` を入れていた（302）。 |
| 07:30:39 | `/invoices/358` を表示（200）。 |
| 07:30:40 | `GET /invoices/358/pdf` を実行。 |
| 07:30:40 | `127.0.0.1` 経由で `PdfRenderController#show` に `/pdf_render/358`、`/1`〜`/5` の順にアクセス。**すべて 200**。 |
| 07:30:40 | `TE-2026-0007.pdf` を攻撃元に送信（200）。 |

IP 別の行数: ALB ヘルスチェック（`10.20.0.236` / `10.20.1.190`）各 78、`127.0.0.1`（PDF 生成の内部アクセス）30、`182.250.54.35` 14。

## 問いへの回答

### 誰の、何が、どこまで見られたか
- **何が**: `pdf_render` が返す請求書の内容（取引先名、金額、明細、振込先口座）。PDF の中身自体はログに出ないが、レンダリング結果が PDF に入って返った可能性が高い。
- **どこまで**: このログでは請求書 ID 1〜5。ID 358 は攻撃者自身が作成したもの。
- **誰の**: 未特定。アプリログに ID と組織の対応は出ない。DB の `invoices.organization_id` で確認が必要。
- **攻撃者のアカウント**: アプリログに user / organization が出ない。ID 358 の作成者を DB で特定する必要がある。

### みなと製麺だけか
- 判断できない。ID 1〜5 は `db/seeds.rb` から、みなと製麺を含む先頭の組織と推測されるが、実際の対応は未確認。
- ログに写っていない時間帯に ID 6〜357 を取得された可能性がある（ID は連番）。

### ログはいつまでさかのぼれるか
- 手元のログは約 13 分のみ。保持期間、ロググループ名、全期間の件数は未確認。
- Rails ログには `request_id` と `remote_ip` はあるが、ユーザー ID やセッションは出ない。`pdf_render` の応答内容も出ない。
- ALB / CloudFront のアクセスログが有効かは未確認。
- `audit_logs` と `auth_logs` は DB 側にあり、CloudWatch の保持期間に関係なく全期間を追える可能性が高い。

## 時系列上の注意
PR #1（`pdf_render` 削除）のマージは 2026-11-21 07:39:19 UTC。攻撃は 07:30:40 UTC で、マージ前。本番へのデプロイ時刻は未確認のため、**デプロイ済みか確認し、未デプロイなら急ぐこと**。デプロイ後は同様の攻撃は成立しないが、それ以前の漏えいは取り消せない。

## 追加調査

### CloudWatch Logs Insights（アプリのロググループ、期間は保持期間の最大）
```
fields @timestamp, @message
| filter @message like /pdf_render/ and @message like /Started GET/
| sort @timestamp asc
```
```
fields @timestamp, @message
| filter @message like /Parameters/ and (@message like /iframe/ or @message like /127.0.0.1/ or @message like /<script/)
| sort @timestamp asc
```
```
fields @timestamp, @message
| filter @message like /182.250.54.35/
| sort @timestamp asc
```
確認すること: `pdf_render` への 127.0.0.1 からのアクセス件数と ID の範囲、攻撃者 IP の最初の出現時刻、メモ欄に HTML を送った `create` / `update` の有無。

### DB（本番 RDS、読み取り専用）
- `SELECT id, organization_id, customer_name FROM invoices WHERE id IN (1,2,3,4,5,358);` で、読まれた組織を特定する。
- `invoices.notes` に `pdf_render`、`<iframe`、`127.0.0.1` を含む行を全件検索する。
- `audit_logs` の `action = 'invoice.pdf'` を、ユーザー別・IP 別・時刻別に集計する。
- ID 358 の作成者の user、organization、サインアップ日時、使った招待コードを確認する。
- `bank_account_id` が他組織の口座を指す請求書を洗い出す（SQL は `docs/vulun-report/report.md`）。

### ログの範囲の確認
- ロググループの保持期間、`storedBytes`、最古のログイベントの時刻を確認する。
- ALB / CloudFront のアクセスログの有効化、保存先、保持期間を確認する。

## 対応
- 攻撃元 IP `182.250.54.35` を遮断する（CloudFront の WAF や ALB のセキュリティグループ）。
- 修正のデプロイを確認し、ログに `pdf_render` への新たなアクセスがないか監視する。
- `SECRET_KEY_BASE`、DB パスワード、招待コードをローテーションする。
- 被害組織が特定でき次第、顧客へ通知する。
- 今後のため、アプリログに user ID / organization ID を出す。ログの保持期間を延ばす。

## 補足
- 渡された AWS コンソールのパスワードは、チャットに平文で出ている。調査後に変更し、アカウントを無効化すること。
