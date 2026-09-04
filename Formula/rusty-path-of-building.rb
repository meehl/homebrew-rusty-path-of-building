class RustyPathOfBuilding < Formula
  desc "Cross-platform runtime for Path of Building"
  homepage "https://github.com/meehl/rusty-path-of-building"
  url "https://github.com/meehl/rusty-path-of-building/archive/refs/tags/v0.2.18.tar.gz"
  sha256 "4d1b744098fd91a18e70f5570eee6dbe77f42c814c6af2e34edfac32cad12c2f"
  license "MIT"
  head "https://github.com/meehl/rusty-path-of-building.git", branch: "main"

  depends_on "luarocks" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "luajit"

  uses_from_macos "curl"
  uses_from_macos "zlib"

  # PoB's Lua code requires these C modules at runtime. They have to be built
  # against LuaJIT (Lua 5.1), not the default Lua that luarocks targets.
  resource "luautf8" do
    url "https://luarocks.org/luautf8-0.2.1-1.src.rock"
    sha256 "70c1590a6c2cfca417755b0bc79207bdfd0b469f854bfcc4e2cc5a39b5e3e3b6"
  end

  resource "luasocket" do
    url "https://luarocks.org/luasocket-3.1.0-1.src.rock"
    sha256 "f4a207f50a3f99ad65def8e29c54ac9aac668b216476f7fae3fae92413398ed2"
  end

  resource "lua-curl" do
    url "https://luarocks.org/lua-curl-0.3.13-1.src.rock"
    sha256 "6b2cc48621fac3cb7c1669705475e67a6932829ba46efb9ac5864604848f8ea2"
  end

  def install
    system "cargo", "install", *std_cargo_args

    lua_tree = libexec/"lua"
    rocks = buildpath/"rocks"
    rocks.mkpath
    resources.each do |r|
      rock = rocks/File.basename(r.url)
      cp r.fetch, rock
      # --only-server keeps luarocks from reaching out to luarocks.org.
      system "luarocks", "install", "--lua-version=5.1", "--tree=#{lua_tree}",
             "--only-server=#{rocks}", rock
    end

    # lzip is not on luarocks; its source ships in this repo.
    cd "lua/libs/lzip" do
      system "make", "LUA_IMPL=luajit", "CC=#{ENV.cxx}"
      (lua_tree/"lib/lua/5.1").install "lzip.so"
    end

    # PoB finds its C modules through Lua's standard search paths, so point
    # LuaJIT at the private tree rather than making the user run
    # `luarocks path` into a shell profile.
    lua_path = "#{lua_tree}/share/lua/5.1/?.lua;#{lua_tree}/share/lua/5.1/?/init.lua;;"
    lua_cpath = "#{lua_tree}/lib/lua/5.1/?.so;;"
    libexec.install bin/"rusty-path-of-building"
    (bin/"rusty-path-of-building").write_env_script libexec/"rusty-path-of-building",
                                                    LUA_PATH:      lua_path,
                                                    LUA_CPATH:     lua_cpath,
                                                    LUA_PATH_5_1:  lua_path,
                                                    LUA_CPATH_5_1: lua_cpath
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
    assert_match version.to_s, shell_output("#{bin}/rusty-path-of-building --version")

    ENV["LUA_PATH"] = "#{libexec}/lua/share/lua/5.1/?.lua;#{libexec}/lua/share/lua/5.1/?/init.lua;;"
    ENV["LUA_CPATH"] = "#{libexec}/lua/lib/lua/5.1/?.so;;"
    %w[lua-utf8 socket.core cURL lzip].each do |mod|
      system formula_opt_bin("luajit")/"luajit", "-e", "assert(require('#{mod}'))"
    end
  end
end
