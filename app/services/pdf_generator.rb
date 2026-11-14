require "open3"

# Converts a rendered invoice page into a PDF using wkhtmltopdf.
#
# wkhtmltopdf fetches the given URL, renders it with its bundled WebKit, and
# writes the PDF to stdout. The binary version is pinned by the Docker image.
class PdfGenerator
  class RenderError < StandardError; end

  # Base URL the PDF renderer uses to fetch the invoice's HTML.
  def self.internal_base_url
    ENV.fetch("INTERNAL_BASE_URL", "http://127.0.0.1:#{ENV.fetch('PORT', 3000)}")
  end

  def self.binary
    ENV.fetch("WKHTMLTOPDF_PATH", "wkhtmltopdf")
  end

  def self.render(url)
    args = [
      binary,
      "--encoding", "utf-8",
      "--page-size", "A4",
      "--quiet",
      url,
      "-" # write PDF to stdout
    ]

    out, err, status = Open3.capture3(*args, binmode: true)
    raise RenderError, "wkhtmltopdf failed (#{status.exitstatus}): #{err}" unless status.success?

    out
  end
end
