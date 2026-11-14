require "test_helper"

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

  test "内部レンダリング用エンドポイントは非ローカルからのアクセスを拒否する" do
    get pdf_render_path(@invoice_b), headers: { "REMOTE_ADDR" => "203.0.113.9" }
    assert_response :forbidden
  end
end
