# Minimal development seed data so the app is usable locally.
if Rails.env.production?
  warn "Refusing to run demo seeds in production."
  exit 0
end

org = Organization.find_or_create_by!(name: "みなと製麺")

admin = org.users.find_or_initialize_by(email: "admin@minato-seimen.example")
admin.update!(name: "運用担当", password: "donburi-demo-pw")

bank = org.bank_accounts.find_or_create_by!(account_number: "1234567") do |b|
  b.bank_name = "みなと銀行"
  b.branch_name = "本店"
  b.account_type = "普通"
  b.holder_name = "カ）ミナトセイメン"
end

if org.invoices.none?
  3.times do |i|
    invoice = org.invoices.build(
      number: org.next_invoice_number(prefix: "MN"),
      customer_name: "取引先#{i + 1}",
      bank_account: bank,
      status: "sent",
      due_on: Date.current + 30,
      notes: "いつもお世話になっております。"
    )
    invoice.invoice_lines.build(description: "ラーメンスープ 業務用 20L", quantity: 10, unit_price: 50_000)
    invoice.save!
  end
end

puts "Seeded: #{Organization.count} org, #{User.count} user, #{Invoice.count} invoices."
puts "Login: admin@minato-seimen.example / donburi-demo-pw"
