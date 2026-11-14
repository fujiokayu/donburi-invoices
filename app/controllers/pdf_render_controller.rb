class PdfRenderController < ActionController::Base
  layout "pdf"

  before_action :require_local

  def show
    @invoice = Invoice.find(params[:id])
    render template: "invoices/pdf", formats: [:html]
  end

  private

  def require_local
    head :forbidden unless request.local?
  end
end
