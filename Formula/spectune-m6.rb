class SpectuneM6 < Formula
  desc "Qwen and DFlash2 with packed-Q4 kernels for Apple M6"
  homepage "https://github.com/Gage-Weaver/spectune-m6"
  url "https://github.com/Gage-Weaver/spectune-m6/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "b907580e6b5c5cfc7a02a3a647502bf931508f58af05275679eca331fce0ae3d"
  license "Apache-2.0"

  depends_on :macos
  depends_on arch: :arm64
  depends_on "uv"

  def install
    # v0.1.0 keeps state in the checkout. These packaging-only changes move it
    # outside the Cellar so upgrades preserve the runtime and downloaded models.
    if version == Version.new("0.1.0")
      inreplace "run", 'export UV_PROJECT_ENVIRONMENT="$root/.venv"',
                      'export UV_PROJECT_ENVIRONMENT="${SPECTUNE_ENV_DIR:-$root/.venv}"'
      inreplace "spectune_m6/__main__.py", "import json\n", "import json\nimport os\n"
      inreplace "spectune_m6/__main__.py",
                'log_dir = Path(__file__).resolve().parent.parent / "logs"',
                'log_dir = Path(os.environ["SPECTUNE_STATE_DIR"]) / "logs"'
    end
    libexec.install "run", "spectune_m6", "pyproject.toml", "uv.lock", ".python-version", "LICENSE", "NOTICE", "licenses"
    (bin/"spectune-m6").write <<~SH
      #!/bin/bash
      set -euo pipefail
      export SPECTUNE_CACHE="${SPECTUNE_CACHE:-${XDG_CACHE_HOME:-$HOME/Library/Caches}/spectune-m6}"
      export SPECTUNE_STATE_DIR="${SPECTUNE_STATE_DIR:-$HOME/Library/Application Support/spectune-m6}"
      export SPECTUNE_ENV_DIR="$SPECTUNE_STATE_DIR/venvs/#{version}"
      mkdir -p "$SPECTUNE_STATE_DIR"
      exec "#{libexec}/run" "$@"
    SH
  end

  def caveats
    <<~EOS
      Requires an M6 Mac with 32 GB+ unified memory and macOS 26.2+.
      First launch installs the pinned runtime and downloads about 20 GB of weights.
      Set SPECTUNE_CACHE to choose another download directory.
    EOS
  end

  test do
    assert_path_exists libexec/"uv.lock"
    assert_match "SPECTUNE_STATE_DIR", (bin/"spectune-m6").read
    system "bash", "-n", libexec/"run"
  end
end
