require "open3"

# Converts rendered invoice HTML into a PDF using wkhtmltopdf.
#
# [修正] 以前は wkhtmltopdf に内部 URL (http://127.0.0.1/pdf_render/:id) を渡し、
# レンダラ自身にアプリへ HTTP で取りに行かせていた。そのため HTML に混入したタグ
# (<iframe> 等) がサーバ内部からリクエストを発行できた (SSRF)。
# 現在は、コントローラが描画した HTML 文字列を標準入力で渡すだけにしている。
# The binary version is pinned by the Docker image.
class PdfGenerator
  class RenderError < StandardError; end

  def self.binary
    ENV.fetch("WKHTMLTOPDF_PATH", "wkhtmltopdf")
  end

  def self.command
    [
      binary,
      "--encoding", "utf-8",
      "--page-size", "A4",
      "--quiet",
      # [修正] 多層防御: 仮に HTML インジェクションが再発しても、
      # JavaScript (XHR) や file:// を使った読み取りはさせない
      "--disable-javascript",
      "--disable-local-file-access",
      "-", # read HTML from stdin (URL は渡さない)
      "-"  # write PDF to stdout
    ]
  end

  def self.render(html)
    out, err, status = Open3.capture3(*command, stdin_data: html, binmode: true)
    raise RenderError, "wkhtmltopdf failed (#{status.exitstatus}): #{err}" unless status.success?

    out
  end
end
