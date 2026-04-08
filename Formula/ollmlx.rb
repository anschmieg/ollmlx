class Ollmlx < Formula
  desc "Run local LLMs via mlx-lm on Apple Silicon — CLI daemon + OpenAI/Ollama-compatible API"
  homepage "https://github.com/darrylmorley/ollmlx"
  url "https://github.com/darrylmorley/ollmlx/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "718bf42e37888be42aaa679511ee20dc429f4ae9a052c0692b5e96bc6e6ec137"
  license "MIT"
  head "https://github.com/darrylmorley/ollmlx.git", branch: "main"

  depends_on xcode: ["15.0", :build]

  conflicts_with cask: "ollmlx"

  def install
    system "swift", "build", "--configuration", "release", "--target", "ollmlx",
           "--disable-sandbox"
    bin.install ".build/release/ollmlx"
    (pkgshare/"Scripts").install "Scripts/install_mlx_lm.sh"
  end

  service do
    run [opt_bin/"ollmlx", "serve"]
    keep_alive true
    log_path var/"log/ollmlx.log"
    error_log_path var/"log/ollmlx.log"
  end

  def caveats
    <<~EOS
      ollmlx requires Apple Silicon (M1 or later) and a Python environment at
      ~/.ollmlx/venv (containing mlx-lm and huggingface-hub). Bootstrap it once
      before starting the service:

        bash #{pkgshare}/Scripts/install_mlx_lm.sh

      Then start the daemon:

        brew services start ollmlx
    EOS
  end

  test do
    assert_match "ollmlx", shell_output("#{bin}/ollmlx --help")
  end
end
