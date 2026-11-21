require "test_helper"
require "tmpdir"

class PdfGeneratorTest < ActiveSupport::TestCase
  test "レンダラには URL を渡さず、標準入力から HTML を読ませる" do
    cmd = PdfGenerator.command
    assert_equal %w[- -], cmd.last(2)
    assert_empty cmd.grep(%r{\Ahttps?://}), "内部 URL をレンダラに渡してはいけない"
  end

  test "JavaScript とローカルファイルの読み込みを無効化している" do
    cmd = PdfGenerator.command
    assert_includes cmd, "--disable-javascript"
    assert_includes cmd, "--disable-local-file-access"
  end

  test "HTML を標準入力で渡し、標準出力を結果として返す" do
    Dir.mktmpdir do |dir|
      # wkhtmltopdf の代わりに、標準入力をそのまま出力する偽バイナリを使う
      fake = File.join(dir, "fake-wkhtmltopdf")
      File.write(fake, "#!/bin/sh\ncat\n")
      File.chmod(0o755, fake)

      original = ENV["WKHTMLTOPDF_PATH"]
      ENV["WKHTMLTOPDF_PATH"] = fake
      assert_equal "<p>hello</p>", PdfGenerator.render("<p>hello</p>")
    ensure
      ENV["WKHTMLTOPDF_PATH"] = original
    end
  end
end
