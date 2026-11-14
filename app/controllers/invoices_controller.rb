class InvoicesController < ApplicationController
  before_action :require_login
  before_action :set_invoice, only: %i[show edit update destroy pdf]

  def index
    @invoices = current_organization.invoices.order(created_at: :desc)
  end

  def show
  end

  def new
    @invoice = current_organization.invoices.build
    @invoice.invoice_lines.build
  end

  def create
    @invoice = current_organization.invoices.build(invoice_params)
    @invoice.number = current_organization.next_invoice_number(prefix: org_prefix)

    if @invoice.save
      AuditLog.record!(action: "invoice.create", user: current_user, target: @invoice, ip: client_ip)
      redirect_to @invoice, notice: "請求書を作成しました。"
    else
      @invoice.invoice_lines.build if @invoice.invoice_lines.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @invoice.update(invoice_params)
      AuditLog.record!(action: "invoice.update", user: current_user, target: @invoice, ip: client_ip)
      redirect_to @invoice, notice: "請求書を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    AuditLog.record!(action: "invoice.destroy", user: current_user, target: @invoice, ip: client_ip)
    redirect_to invoices_path, notice: "請求書を削除しました。"
  end

  # Export the invoice as a PDF.
  def pdf
    url = "#{PdfGenerator.internal_base_url}/pdf_render/#{@invoice.id}"
    data = PdfGenerator.render(url)
    AuditLog.record!(action: "invoice.pdf", user: current_user, target: @invoice, ip: client_ip)
    send_data data, filename: "#{@invoice.number}.pdf", type: "application/pdf", disposition: "attachment"
  end

  private

  def set_invoice
    @invoice = current_organization.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :customer_name, :amount, :status, :notes, :due_on, :bank_account_id,
      invoice_lines_attributes: %i[id description quantity unit_price position _destroy]
    )
  end

  def org_prefix
    current_organization.name.to_s.gsub(/[^A-Za-z]/, "")[0, 2].upcase.presence || "IN"
  end
end
