# homebrew-qemu-virgl-kosmickrisp

[![Build Status](https://img.shields.io/github/actions/workflow/status/startergo/homebrew-qemu-virgl-kosmickrisp/bottle.yml?branch=master&label=bottle%20build&logo=github&style=flat-square)](https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/actions/workflows/bottle.yml)

Homebrew tap for [QEMU](https://www.qemu.org/) - A generic and open source machine emulator and virtualizer, built for macOS with virglrenderer, ANGLE, and KosmicKrisp support for GPU acceleration.

## What is QEMU?

QEMU is a free and open-source emulator and virtualizer that can perform hardware virtualization. When combined with virglrenderer and KosmicKrisp, it provides accelerated 3D graphics and Vulkan support for guest operating systems.

## Installation

### From Bottle (Recommended - Pre-built Binary)

```bash
# Tap the repository
brew tap startergo/qemu-virgl-kosmickrisp

# Install qemu (downloads pre-built bottle)
brew install startergo/qemu-virgl-kosmickrisp/qemu
```

### From Source

Build from source if you need to modify the formula, apply custom patches, or the bottle is unavailable for your macOS version:

```bash
# Tap the repository
brew tap startergo/qemu-virgl-kosmickrisp

# Install and build from source
brew install --build-from-source startergo/qemu-virgl-kosmickrisp/qemu

# Or use the shorthand
brew install -s startergo/qemu-virgl-kosmickrisp/qemu
```

**Build from source notes:**
- Build time: ~30-60 minutes on Apple Silicon M1/M2/M3 (depending on CPU cores)
- Disk space required: ~4GB for build artifacts
- Requires Xcode Command Line Tools: `xcode-select --install`
- The formula will download and build:
  - QEMU from upstream GitLab master
  - Vulkan SDK with KosmicKrisp component
  - Apply all patches automatically

**Troubleshooting build failures:**

If the build fails, you can inspect the build logs:

```bash
# Show build logs
brew config
brew install --verbose --build-from-source startergo/qemu-virgl-kosmickrisp/qemu

# Or access logs after failed build
cat ~/Library/Logs/Homebrew/qemu/*.log
```

## Dependencies

This tap requires the following taps:
- [startergo/virglrenderer](https://github.com/startergo/homebrew-virglrenderer) - Virtual 3D GPU renderer
- [startergo/libepoxy](https://github.com/startergo/homebrew-libepoxy) - OpenGL function pointer management
- [startergo/angle](https://github.com/startergo/homebrew-angle) - OpenGL ES implementation for macOS

## Usage

### Display Options

The `-display cocoa` backend supports OpenGL rendering modes via the `gl=` option:

- `gl=on` - Enable OpenGL rendering with compatibility profile
- `gl=off` - Disable OpenGL rendering (default)
- `gl=core` - Use OpenGL Core profile (recommended for modern OpenGL)
- `gl=es` - Use OpenGL ES via ANGLE (for ES 2.0/3.0 support)

### Basic VM with virtio-gpu

```bash
qemu-system-x86_64 \
  -display cocoa,gl=core \
  -device virtio-gpu-pci \
  ...
```

### With Vulkan (Venus) support

Venus is a modern virtio-gpu Vulkan transport available in QEMU v9.2.0 and later. The Vulkan runtime (loader, driver, ICD) is installed with QEMU at:
```
$(brew --prefix qemu)/lib/libvulkan.dylib
$(brew --prefix qemu)/lib/libvulkan_kosmickrisp.dylib
$(brew --prefix qemu)/share/vulkan/icd.d/libkosmickrisp_icd.json
```

**Requirements:**
- macOS 15+ (Sequoia) on Apple Silicon for full Vulkan 1.3 conformance
- LunarG Vulkan SDK 1.4.335.1 (KosmicKrisp bundled with QEMU)

```bash
export VK_DRIVER_FILES=$(brew --prefix qemu)/share/vulkan/icd.d/libkosmickrisp_icd.json
export VK_ICD_FILENAMES=$(brew --prefix qemu)/share/vulkan/icd.d/libkosmickrisp_icd.json

qemu-system-x86_64 \
  -accel hvf \
  -display cocoa,gl=core \
  -device virtio-gpu-pci,vulkan=on,hostmem=4G \
  ...
```

**Guest OS requirements:** Linux guest with Mesa 25.1+ for Venus support. Verify inside guest:
```bash
vulkaninfo | grep "device name"
```
Should report virtio-gpu device powered by host's KosmicKrisp.

Note: The KosmicKrisp driver (ICD file + dylib) is bundled with QEMU. No separate Vulkan SDK installation is required.

## What's Included

- **QEMU system binaries**: qemu-system-x86_64, qemu-system-aarch64, qemu-system-i386
- **QEMU tools**: qemu-img, qemu-nbd, qemu-keymap, etc.
- **virtio-gpu-gl support**: Enabled with virglrenderer integration
- **OpenGL ES support**: Via ANGLE through virglrenderer
- **Venus support**: Modern virtio-gpu Vulkan transport via LunarG Vulkan SDK (includes KosmicKrisp, a Vulkan-to-Metal layered driver for Apple Silicon)
- **UI backends**: Cocoa, SDL (GTK disabled to avoid dependency conflicts)

## Build Configuration

This build is configured for macOS with GPU acceleration support:
- **virglrenderer support**: Uses [startergo/virglrenderer](https://github.com/startergo/homebrew-virglrenderer) for GPU acceleration
- **OpenGL ES support via ANGLE**: Through virglrenderer dependency
- **OpenGL support via libepoxy**: Through virglrenderer dependency
- **Venus support**: Modern virtio-gpu Vulkan transport via LunarG Vulkan SDK (includes KosmicKrisp, a Vulkan-to-Metal layered driver for Apple Silicon)
- **Target architectures**: x86_64, aarch64, arm, and more
- Builds against upstream QEMU master

## Patches

This tap applies the following patches to upstream QEMU:
- **[qemu-virgl3d-macos.patch](patches/qemu-virgl3d-macos.patch)**: @akihikodaki's VirGL 3D macOS support with ANGLE Metal backend ([upstream PR](https://patchew.org/search?q=project%3AQEMU+from%3Aakihiko.odaki%40gmail.com))
- **[qemu-audio-coreaudio.patch](patches/qemu-audio-coreaudio.patch)**: Audio/coreaudio improvements for macOS

These patches enable:
- `-display cocoa,gl=core` - OpenGL Core profile via OpenGL.framework
- `-display cocoa,gl=es` - OpenGL ES via ANGLE with Metal backend

## License

GPL-2.0-or-later

## Upstream

- **[QEMU](https://www.qemu.org/)**: Generic and open source machine emulator and virtualizer
- **[virglrenderer](https://gitlab.freedesktop.org/virgl/virglrenderer)**: Virtual 3D GPU renderer (via [startergo/homebrew-virglrenderer](https://github.com/startergo/homebrew-virglrenderer))
- **[ANGLE](https://chromium.googlesource.com/angle/angle)**: OpenGL ES implementation for macOS (via [startergo/homebrew-angle](https://github.com/startergo/homebrew-angle))
- **[libepoxy](https://github.com/anholt/libepoxy)**: OpenGL function pointer management (via [startergo/homebrew-libepoxy](https://github.com/startergo/homebrew-libepoxy))
- **[LunarG Vulkan SDK](https://vulkan.lunarg.com/doc/sdk/1.4.335.1/mac/release_notes.html)**: Vulkan SDK for macOS (includes KosmicKrisp, a Vulkan-to-Metal layered driver for Apple Silicon, currently in alpha)

This tap builds against the latest upstream QEMU with macOS-specific optimizations for graphics acceleration.
