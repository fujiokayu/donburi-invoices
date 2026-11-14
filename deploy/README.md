# Donburi — AWS デプロイ（ECS Fargate）

演習インスタンスを AWS に立てるための Terraform です。

```
CloudFront (HTTPS, ACM) ──> ALB (HTTP, CloudFront 限定) ──> Fargate (Rails)
                                                               └─> RDS PostgreSQL (private)
```

- **CloudFront** が TLS を終端し、`X-Forwarded-Proto: https` を付けて ALB に転送します（アプリは `assume_ssl` で secure Cookie を発行）。
- **ALB** は CloudFront のマネージドプレフィックスリストからのみ受け付けます（直叩き不可）。
- **Fargate タスク**はパブリックサブネット（SG で ALB からのみ許可）。タスクロールは**権限なし**。
- **RDS** はプライベートサブネット。接続情報・`SECRET_KEY_BASE`・`INVITE_CODE` は Secrets Manager。

> ⚠️ これは**意図的に脆弱な訓練用アプリ**をホストします。常設せず、イベント期間中のみ・招待制で公開してください。終了後は `terraform destroy` で畳みます。

## 前提

- Terraform >= 1.6、AWS 認証情報（デプロイ権限）
- Docker（イメージのビルド／push）
- アプリ側で `bundle install` 済み（`Gemfile.lock` が存在すること）

## 手順

```bash
cd deploy
cp terraform.tfvars.example terraform.tfvars   # invite_code などを編集
terraform init

# 1) 先に ECR だけ作る（イメージの置き場）
terraform apply -target=aws_ecr_repository.app

# 2) イメージをビルドして push
export AWS_REGION=ap-northeast-1
REPO=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${REPO%/*}"
docker build --platform linux/arm64 -t "$REPO:latest" ..   # Fargate は ARM64(Graviton)。Apple Silicon/colima でネイティブビルド
docker push "$REPO:latest"

# 3) 残り全部を適用
terraform apply

# 公開 URL
terraform output app_url
```

起動時にコンテナのエントリポイントが `db:prepare`（マイグレーション）を実行します。
**本番 DB はマイグレーションのみで空**です。演習用データの投入は別途行います。

## 独自ドメインを使う場合

1. us-east-1 で ACM 証明書を発行・検証（CloudFront 用は必ず us-east-1）
2. `terraform.tfvars` に `domain_name` と `acm_certificate_arn` を設定
3. `terraform apply` 後、CloudFront のドメインに向けて DNS の CNAME/ALIAS を作成

## 畳む

```bash
terraform destroy
```
