class Qemu < Formula
  desc "Generic and open source machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  license "GPL-2.0-or-later"

  version "1.0.1"
  url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "cd45b938a424afb6beeb1d0b06a86ad06972f1cc2c4850e582819eb516aa7d56"
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  # Apply patch for OpenGL 4.1 support (virgl renderer improvements)
  patch :p1, :path => "#{__dir__}/../patches/qemu-opengl41.patch"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/releases/download/v1.0.1"
    sha256 arm64_sequoia: "e18007b1cb54462f601d18d7bc518b4f225fc15982bb13590f46a714a03d390b"
  end

  # Dependencies for GPU acceleration
  depends_on "startergo/virglrenderer/virglrenderer"

  # Core dependencies
  depends_on "coreutils"
  depends_on "dtc"
  depends_on "glib"
  depends_on "gnutls"
  depends_on "pixman"
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "ninja" => :build
  depends_on "meson" => :build
  depends_on "python@3" => :build
  depends_on "gettext"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libssh"
  depends_on "libusb"
  depends_on "lzo"
  depends_on "ncurses"
  depends_on "nettle"
  depends_on "sdl2"
  depends_on "snappy"
  depends_on "spice-protocol"
  depends_on "spice-server"
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
    angle = Formula["startergo/angle/angle"]
    libepoxy = Formula["startergo/libepoxy/libepoxy"]
    virglrenderer = Formula["startergo/virglrenderer/virglrenderer"]    
    
    angle_pc_path = "#{angle.lib}/pkgconfig"
    libepoxy_pc_path = "#{libepoxy.lib}/pkgconfig"
    virglrenderer_pc_path = "#{virglrenderer.lib}/pkgconfig"

    # Combine pkg-config paths
    combined_pc_path = "#{virglrenderer_pc_path}:#{libepoxy_pc_path}:#{angle_pc_path}"

    # Configure QEMU with virglrenderer and GPU acceleration support
    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-debug
      --disable-silent-rules
      --enable-virglrenderer
      --disable-guest-agent
      --disable-guest-agent-msi
    ]

    # Set pkg-config path for dependencies
    ENV["PKG_CONFIG_PATH"] = "#{combined_pc_path}:#{ENV["PKG_CONFIG_PATH"]}"

    # Set library path for runtime linking
    ENV["DYLD_FALLBACK_LIBRARY_PATH"] = "#{virglrenderer.lib}:#{libepoxy.lib}:#{angle.lib}:#{ENV["DYLD_FALLBACK_LIBRARY_PATH"]}"

    # Add smbd path
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"
    
    # Only build specific targets: aarch64, x86_64, and i386
    args << "--target-list=aarch64-softmmu,x86_64-softmmu,i386-softmmu"


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
