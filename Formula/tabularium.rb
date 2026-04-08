class Tabularium < Formula
  desc "AI-oriented markdown document store with CLI and HTTP server"
  homepage "https://github.com/eva-ics/tabularium"
  license "Apache-2.0"
  version "0.1.4"

  on_macos do
    url "https://github.com/eva-ics/tabularium/releases/download/v0.1.4/tb-v0.1.4-aarch64-apple-darwin.tar.gz"
    sha256 "480bd09363f1f7782d2589d4557beeb0f315ed6c5e3aeeadaadc7077a8476bcd"

    resource "tabularium-server-bin" do
      url "https://github.com/eva-ics/tabularium/releases/download/v0.1.4/tabularium-server-v0.1.4-aarch64-apple-darwin.tar.gz"
      sha256 "ce8122a6f42e13ebd66aed0d9d73d5849e0428b687249153d5625ba4f696b862"
    end
  end

  on_linux do
    url "https://github.com/eva-ics/tabularium/releases/download/v0.1.4/tb-v0.1.4-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "c39f57ce07cad26bf51d6dc04e60239eb6da92823b3bddb906d52c8b6ad78a5f"

    resource "tabularium-server-bin" do
      url "https://github.com/eva-ics/tabularium/releases/download/v0.1.4/tabularium-server-v0.1.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "d0c506f1d6e5cea4bed62c4a4d6785fe4006735c5b201542f051f335fd741747"
    end
  end

  resource "default-config" do
    url "https://raw.githubusercontent.com/eva-ics/tabularium/v0.1.4/config.toml.example"
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
