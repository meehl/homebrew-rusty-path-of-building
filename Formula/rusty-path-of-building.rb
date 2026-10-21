class RustyPathOfBuilding < Formula
  desc "Cross-platform runtime for Path of Building"
  homepage "https://github.com/meehl/rusty-path-of-building"
  url "https://github.com/meehl/rusty-path-of-building/archive/refs/tags/v0.3.4.tar.gz"
  sha256 "5eb841d8e457e8d4bf04824790503dcaf47854d98b9a703ec5f828a29b068418"
  license "MIT"
  head "https://github.com/meehl/rusty-path-of-building.git", branch: "main"

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "luajit"

  uses_from_macos "curl"

  def install
    system "cargo", "install", *std_cargo_args

    libexec.install bin/"rusty-path-of-building"
    bin.install_symlink libexec/"rusty-path-of-building"
  end

  def caveats
    <<~EOS
      Launch Path of Building 1 or 2 with:
        rusty-path-of-building poe1
        rusty-path-of-building poe2

      PoB downloads its own data and Lua code on first run into:
        ~/Library/Application Support/RustyPathOfBuilding{1,2}
    EOS
  end

  test do
    assert_match version.to_s,
      shell_output("#{bin}/rusty-path-of-building --version")
  end
end
