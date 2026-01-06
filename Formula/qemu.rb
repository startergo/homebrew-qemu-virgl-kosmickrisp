class Qemu < Formula
  desc "Generic and open source machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  license "GPL-2.0-or-later"

  version "1.0.1"
  url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "b92c633671d165b8d49c18b537566079741b891b29a54f555e6e0a86a4ded4a9"
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/releases/download/v1.0.1"
    sha256 arm64_sequoia: "e18007b1cb54462f601d18d7bc518b4f225fc15982bb13590f46a714a03d390b"
  end

  # Dependencies for GPU acceleration
  depends_on "startergo/virglrenderer/virglrenderer"
  depends_on "startergo/libepoxy/libepoxy"
  depends_on "startergo/angle/angle"

  # Core dependencies
  depends_on "glib"
  depends_on "pixman"
  depends_on "pkg-config" => :build
  depends_on "ninja" => :build
  depends_on "meson" => :build
  depends_on "python@3" => :build
  depends_on "gettext"
  depends_on "gnutls"
  depends_on "libslirp"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "vde"
  depends_on "gmp"
  depends_on "zstd"

  def install
    # Install pyyaml for meson
    system "python3", "-m", "pip", "install", "--break-system-packages", "pyyaml"

    # Download upstream QEMU source from GitLab master
    upstream_url = "https://gitlab.com/qemu-project/qemu/-/archive/master/qemu-master.tar.gz"
    ohai "Downloading upstream QEMU from #{upstream_url}"
    system "curl", "-L", upstream_url, "-o", "qemu.tar.gz"
    system "tar", "-xzf", "qemu.tar.gz", "--strip-components=1"

    # Get dependency paths for GPU acceleration
    virglrenderer = Formula["startergo/virglrenderer/virglrenderer"]
    libepoxy = Formula["startergo/libepoxy/libepoxy"]
    angle = Formula["startergo/angle/angle"]

    virglrenderer_pc_path = "#{virglrenderer.lib}/pkgconfig"
    libepoxy_pc_path = "#{libepoxy.lib}/pkgconfig"
    angle_pc_path = "#{angle.lib}/pkgconfig"

    # Combine pkg-config paths
    combined_pc_path = "#{virglrenderer_pc_path}:#{libepoxy_pc_path}:#{angle_pc_path}"

    # Configure QEMU with virglrenderer and GPU acceleration support
    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-debug
      --disable-silent-rules
      --enable-curses
      --enable-libssh
      --enable-virglrenderer
      --enable-opengl
      --enable-gtk
      --enable-cocoa
      --enable-sdl
      --enable-vnc
      --enable-vnc-jpeg
      --enable-vnc-png
      --enable-slirp
      --enable-uuid
      --enable-vhost-net
      --enable-vhost-crypto
      --enable-vhost-kernel
      --enable-vhost-user
      --enable-vhost-user-blk
      --enable-vhost-vdpa
      --disable-guest-agent
      --disable-guest-agent-msi
    ]

    # Set pkg-config path for dependencies
    ENV["PKG_CONFIG_PATH"] = "#{combined_pc_path}:#{ENV["PKG_CONFIG_PATH"]}"

    # Set library path for runtime linking
    ENV["DYLD_FALLBACK_LIBRARY_PATH"] = "#{virglrenderer.lib}:#{libepoxy.lib}:#{angle.lib}:#{ENV["DYLD_FALLBACK_LIBRARY_PATH"]}"

    system "./configure", *args
    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"
  end

  test do
    # Test that qemu-system-x86_64 runs and shows version
    system bin/"qemu-system-x86_64", "--version"
    # Test qemu-img
    system bin/"qemu-img", "--version"
  end
end
