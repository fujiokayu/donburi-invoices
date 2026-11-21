require "test_helper"
require "minitest/mock"

class InvoicesAccessTest < ActionDispatch::IntegrationTest
  setup do
    @org_a = Organization.create!(name: "A製麺")
    @user_a = @org_a.users.create!(name: "a", email: "a@example.com", password: "password-12")

    @org_b = Organization.create!(name: "B製麺")
    @user_b = @org_b.users.create!(name: "b", email: "b@example.com", password: "password-12")
    @invoice_b = @org_b.invoices.create!(number: "B-2026-0001", customer_name: "B社の取引先")
  end

  def login(user)
    post login_path, params: { email: user.email, password: "password-12" }
  end

  test "請求書一覧はログインが必要" do
    get invoices_path
    assert_redirected_to login_path
  end

  test "他テナントの請求書は通常の画面からは参照できない" do
    login(@user_a)
    get invoice_path(@invoice_b)
    assert_response :not_found
  end

  test "自テナントの請求書は参照できる" do
    login(@user_b)
    get invoice_path(@invoice_b)
    assert_response :success
  end

  # --- [修正] PDF 出力経由の SSRF / テナント越えの再発防止 ---------------------

  test "テナントを絞り込まない内部レンダリング用エンドポイントは存在しない" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/pdf_render/#{@invoice_b.id}")
    end
  end

  test "PDF 出力: 備考の HTML はエスケープされ、他テナントの請求書は混入しない" do
    invoice_a = @org_a.invoices.create!(
      number: "A-2026-0001", customer_name: "A社の取引先",
      notes: %(<iframe src="http://127.0.0.1:3000/pdf_render/#{@invoice_b.id}"></iframe>)
    )
    login(@user_a)

    rendered = nil
    PdfGenerator.stub(:render, ->(html) { rendered = html; "%PDF-" }) do
      get pdf_invoice_path(invoice_a)
    end

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_not_includes rendered, "<iframe", "備考がタグとして解釈されてはいけない"
    assert_includes rendered, "&lt;iframe"
    assert_not_includes rendered, "B社の取引先"
  end
end
