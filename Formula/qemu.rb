class Qemu < Formula
  desc "Generic and open source machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  license "GPL-2.0-or-later"

  version "1.0.0"
  url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "5f360ca60fb874c08a130b6d91a340fdcdaa7a6213d28a772a03ea4f8178ead3"
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/releases/download/v1.0.0"
    sha256 arm64_sequoia: "e08b250cc6e653df6a0df8b34eea93bc2d4a6a3205d9608598a104cf8d177855"
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

    # Apply patch for OpenGL 4.1 support (virgl renderer improvements)
    patch_file = "#{__dir__}/../patches/qemu-opengl41.patch"
    ohai "Applying OpenGL 4.1 support patch..."
    system "patch", "-p1", "--batch", "--verbose", "-i", patch_file

    # Download and extract LunarG Vulkan SDK for Venus (KosmicKrisp) support
    vulkan_sdk_version = "1.4.335.1"
    vulkan_sdk_url = "https://sdk.lunarg.com/sdk/download/#{vulkan_sdk_version}/mac/vulkansdk-macos-#{vulkan_sdk_version}.zip"
    ohai "Downloading LunarG Vulkan SDK #{vulkan_sdk_version}..."
    system "curl", "-L", vulkan_sdk_url, "-o", "vulkan-sdk.zip"
    system "unzip", "-q", "vulkan-sdk.zip"

    # Run CLI installer to extract SDK to temporary directory
    vulkan_app = "vulkansdk-macOS-#{vulkan_sdk_version}.app"
    vulkan_install_dir = "#{buildpath}/vulkansdk-install"
    ohai "Extracting Vulkan SDK..."
    system "#{vulkan_app}/Contents/MacOS/vulkansdk-macOS-#{vulkan_sdk_version}",
           "--root", vulkan_install_dir,
           "--accept-licenses",
           "--default-answer",
           "--confirm-command",
           "install"

    # The installer creates a macOS subdirectory
    vulkan_source = "#{vulkan_install_dir}/macOS"
    vulkan_icd = "#{vulkan_source}/share/vulkan/icd.d/libkosmickrisp_icd.json"
    vulkan_driver = "#{vulkan_source}/lib/libvulkan_kosmickrisp.dylib"
    vulkan_loader = "#{vulkan_source}/lib/libvulkan.1.4.335.dylib"

    unless File.exist?(vulkan_icd) && File.exist?(vulkan_driver) && File.exist?(vulkan_loader)
      odie "Vulkan SDK installation failed. Files not found in #{vulkan_source}"
    end

    mkdir_p "#{share}/vulkan/icd.d"
    mkdir_p "#{lib}"
    cp vulkan_icd, "#{share}/vulkan/icd.d/"
    cp vulkan_driver, "#{lib}/"
    cp vulkan_loader, "#{lib}/"
    ln_sf "libvulkan.1.4.335.dylib", "#{lib}/libvulkan.1.dylib"
    ln_sf "libvulkan.1.dylib", "#{lib}/libvulkan.dylib"

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
      --enable-virglrenderer
      --enable-opengl
      --enable-cocoa
      --disable-gtk
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
