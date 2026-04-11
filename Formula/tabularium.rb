class Tabularium < Formula
  desc "AI-oriented markdown document store with CLI and HTTP server"
  homepage "https://github.com/eva-ics/tabularium"
  license "Apache-2.0"
  version "0.1.5"

  on_macos do
    url "https://github.com/eva-ics/tabularium/releases/download/v0.1.5/tb-v0.1.5-aarch64-apple-darwin.tar.gz"
    sha256 "301498a8a53d04069b81568e656a3ea98a900cc64b813c5675fbab991f665251"

    resource "tabularium-server-bin" do
      url "https://github.com/eva-ics/tabularium/releases/download/v0.1.5/tabularium-server-v0.1.5-aarch64-apple-darwin.tar.gz"
      sha256 "20b7ee714fdb762fa58bcc0b152073e9609bd49d72d4f546fd557985d214618f"
    end
  end

  on_linux do
    url "https://github.com/eva-ics/tabularium/releases/download/v0.1.5/tb-v0.1.5-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "23057dca8e356594320be215ecaf0f0d06006f11970ba829c8d036e7c765294b"

    resource "tabularium-server-bin" do
      url "https://github.com/eva-ics/tabularium/releases/download/v0.1.5/tabularium-server-v0.1.5-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "3d05938d2b4882117c9e6677e9c203b56104220f0c297e000c3ae637ba9a02e9"
    end
  end

  resource "default-config" do
    url "https://raw.githubusercontent.com/eva-ics/tabularium/v0.1.5/config.toml.example"
    sha256 "c581ecebdc67c0b057f1920345a7eb99458741fbb45b8e840212dbd9beac096d"
  end

  def install
    bin.install "tb"
    resource("tabularium-server-bin").stage do
      bin.install "tabularium-server"
    end
    (etc/"tabularium").mkpath
    unless (etc/"tabularium/config.toml").exist?
      resource("default-config").stage do
        cp "config.toml.example", etc/"tabularium/config.toml"
      end
      inreplace etc/"tabularium/config.toml" do |s|
        s.gsub!("./data/tabularium.db", "#{var}/tabularium/tabularium.db")
        s.gsub!("./data/tabularium.index", "#{var}/tabularium/tabularium.index")
      end
    end
  end

  def post_install
    (var/"tabularium").mkpath
  end

  service do
    run [opt_bin/"tabularium-server", "--config", etc/"tabularium/config.toml"]
    keep_alive true
    working_dir var/"tabularium"
    log_path var/"log/tabularium.log"
    error_log_path var/"log/tabularium.error.log"
  end

  test do
    assert_predicate bin/"tb", :exist?
    assert_predicate bin/"tabularium-server", :exist?
  end
end
