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

  test "内部レンダリング用エンドポイントは存在しない" do
    assert_raises(ActionController::RoutingError) { get "/pdf_render/#{@invoice_b.id}" }
  end

  test "請求書のメモはHTMLエスケープされる" do
    login(@user_b)
    @invoice_b.update!(notes: "<script>alert(1)</script>")
    get invoice_path(@invoice_b)
    assert_no_match "<script>alert(1)</script>", response.body
  end

  test "他テナントの銀行口座は請求書に指定できない" do
    account_a = @org_a.bank_accounts.create!(bank_name: "A銀行", account_number: "1", holder_name: "A")
    login(@user_b)
    patch invoice_path(@invoice_b), params: { invoice: { bank_account_id: account_a.id } }
    assert_response :unprocessable_entity
    assert_nil @invoice_b.reload.bank_account_id
  end
end
