require "open3"

# Converts rendered invoice HTML into a PDF using wkhtmltopdf.
#
# The HTML is passed via stdin, so the renderer never fetches an application
# URL. JavaScript and local file access are disabled because the HTML contains
# user-provided content. The binary version is pinned by the Docker image.
class PdfGenerator
  class RenderError < StandardError; end

  def self.binary
    ENV.fetch("WKHTMLTOPDF_PATH", "wkhtmltopdf")
  end

  def self.render_html(html)
    args = [
      binary,
      "--encoding", "utf-8",
      "--page-size", "A4",
      "--quiet",
      "--disable-javascript",
      "--disable-local-file-access",
      "-", # read HTML from stdin
      "-"  # write PDF to stdout
    ]

    out, err, status = Open3.capture3(*args, stdin_data: html, binmode: true)
    raise RenderError, "wkhtmltopdf failed (#{status.exitstatus}): #{err}" unless status.success?

    out
  end
end
