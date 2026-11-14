require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "みなと製麺")
  end

  test "テナントごとの連番で請求書番号を払い出す" do
    n1 = @org.next_invoice_number(prefix: "MN", year: 2026)
    n2 = @org.next_invoice_number(prefix: "MN", year: 2026)
    assert_equal "MN-2026-0001", n1
    assert_equal "MN-2026-0002", n2
  end

  test "明細があれば合計金額を明細から同期する" do
    invoice = @org.invoices.build(number: "MN-2026-0001", customer_name: "取引先")
    invoice.invoice_lines.build(description: "スープ", quantity: 3, unit_price: 100_000)
    invoice.save!
    assert_equal 300_000, invoice.amount
  end

  test "金額・単価は円単位の整数で扱う" do
    invoice = @org.invoices.build(number: "MN-2026-0002", customer_name: "取引先")
    invoice.invoice_lines.build(description: "麺", quantity: 2, unit_price: 1_500)
    invoice.save!
    assert_equal 1_500, invoice.invoice_lines.first.unit_price
    assert_equal 3_000, invoice.invoice_lines.first.subtotal
    assert_equal 3_000, invoice.amount
  end
end
