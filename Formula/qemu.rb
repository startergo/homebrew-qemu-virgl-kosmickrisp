class Qemu < Formula
  desc "Generic and open source machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  license "GPL-2.0-or-later"

  version "1.0.10"
  version "1.0.11"
  url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/archive/b560f4befa3468be84699757ab3159b13fb51a99.tar.gz"
  sha256 "774e2242079ea5ae215f6ca129e8c271c2c63bd9b8a88b6a498068dcffd6e70f"
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  bottle do
    root_url "https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/releases/download/v1.0.11"
    sha256 arm64_sequoia: "1b14cf9668c49d72bd31d813bb7acd9938d2bb64afbd519008f3e2a216cc0a8d"
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

    # Apply audio/coreaudio fixes from qemu-opengl41.patch
    patch_audio = "#{__dir__}/../patches/qemu-audio-coreaudio.patch"
    if File.exist?(patch_audio)
      ohai "Applying audio/coreaudio fixes..."
      system "patch", "-p1", "--batch", "--verbose", "-i", patch_audio
    end

    # Apply @akihikodaki's VirGL 3D macOS patch with ANGLE Metal backend
    patch_virgl = "#{__dir__}/../patches/qemu-virgl3d-macos.patch"
    ohai "Applying VirGL 3D macOS patch with ANGLE Metal backend..."
    system "patch", "-p1", "--batch", "--verbose", "-i", patch_virgl

    # Apply NSOpenGLContext fix for Desktop GL (gl=core)
    patch_nsopengl = "#{__dir__}/../patches/qemu-virgl3d-macos-nsopengl.patch"
    ohai "Applying NSOpenGLContext fix for Desktop GL..."
    system "patch", "-p1", "--batch", "--verbose", "-i", patch_nsopengl

    # Apply texture borrowing mechanism for Desktop GL display initialization
    patch_texture_borrowing = "#{__dir__}/../patches/qemu-texture-borrowing.patch"
    if File.exist?(patch_texture_borrowing)
      ohai "Applying texture borrowing mechanism for Desktop GL..."
      system "patch", "-p1", "--batch", "--verbose", "-i", patch_texture_borrowing
    end

    # Download and install Vulkan SDK with KosmicKrisp for Venus support
    # KosmicKrisp is an optional component that must be explicitly selected
    vulkan_sdk_version = "1.4.335.1"
    vulkan_sdk_url = "https://sdk.lunarg.com/sdk/download/#{vulkan_sdk_version}/mac/vulkansdk-macos-#{vulkan_sdk_version}.zip"
    ohai "Downloading Vulkan SDK..."
    system "curl", "-L", vulkan_sdk_url, "-o", "vulkan-sdk.zip"
    system "unzip", "-q", "vulkan-sdk.zip"

    # Run installer with KosmicKrisp component (downloads from cloud)
    # Use --cache-path to set writable cache directory in buildpath
    vulkan_app = "vulkansdk-macOS-#{vulkan_sdk_version}.app"
    vulkan_install_path = "#{buildpath}/vulkan-sdk"
    qt_cache_path = "#{buildpath}/qt-cache"
    mkdir_p qt_cache_path
    ohai "Installing Vulkan SDK with KosmicKrisp (this may take a while)..."

    with_env(QT_QPA_PLATFORM: "offscreen") do
      system "#{vulkan_app}/Contents/MacOS/vulkansdk-macOS-#{vulkan_sdk_version}",
             "--root", vulkan_install_path,
             "--cache-path", qt_cache_path,
             "--accept-licenses",
             "--default-answer",
             "--confirm-command",
             "install", "com.lunarg.vulkan.core", "com.lunarg.vulkan.kosmic"
    end

    # Copy Vulkan runtime files (loader, KosmicKrisp driver, ICD)
    mkdir_p "#{share}/vulkan/icd.d"
    mkdir_p "#{lib}"
    cp "#{vulkan_install_path}/macOS/share/vulkan/icd.d/libkosmickrisp_icd.json", "#{share}/vulkan/icd.d/"
    cp "#{vulkan_install_path}/macOS/lib/libvulkan_kosmickrisp.dylib", "#{lib}/"
    cp "#{vulkan_install_path}/macOS/lib/libvulkan.1.4.335.dylib", "#{lib}/"
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

    # Add rpath so dlopen finds ANGLE libraries at runtime
    # ANGLE uses @rpath/libEGL.dylib, so we need rpath to HOMEBREW_PREFIX/lib
    Dir["#{bin}/*"].each do |binary|
      system "install_name_tool", "-add_rpath", "#{HOMEBREW_PREFIX}/lib", binary
    end
  end

  # No post_install needed - rpath is set during install

  test do
    # Test that qemu-system-x86_64 runs and shows version
    system bin/"qemu-system-x86_64", "--version"
    # Test qemu-img
    system bin/"qemu-img", "--version"
  end
end
