# homebrew-qemu-virgl-kosmickrisp

[![Build Status](https://img.shields.io/github/actions/workflow/status/startergo/homebrew-qemu-virgl-kosmickrisp/bottle.yml?branch=master&label=bottle%20build&logo=github&style=flat-square)](https://github.com/startergo/homebrew-qemu-virgl-kosmickrisp/actions/workflows/bottle.yml)

Homebrew tap for [QEMU](https://www.qemu.org/) - A generic and open source machine emulator and virtualizer, built for macOS with virglrenderer, ANGLE, and KosmicKrisp support for GPU acceleration.

## What is QEMU?

QEMU is a free and open-source emulator and virtualizer that can perform hardware virtualization. When combined with virglrenderer and KosmicKrisp, it provides accelerated 3D graphics and Vulkan support for guest operating systems.

## Installation

```bash
# Tap the repository
brew tap startergo/qemu-virgl-kosmickrisp

# Install qemu
brew install startergo/qemu-virgl-kosmickrisp/qemu
```

## Dependencies

This tap requires the following taps:
- [startergo/virglrenderer](https://github.com/startergo/homebrew-virglrenderer) - Virtual 3D GPU renderer
- [startergo/libepoxy](https://github.com/startergo/homebrew-libepoxy) - OpenGL function pointer management
- [startergo/angle](https://github.com/startergo/homebrew-angle) - OpenGL ES implementation for macOS

## Usage

### Basic VM with virtio-gpu-gl

```bash
qemu-system-x86_64 \
  -display cocoa,gl=on \
  -virtio-gpu-gl,present=on \
  -device virtio-gpu-pci,gl=true \
  ...
```

### With Venus (Vulkan) support

```bash
qemu-system-x86_64 \
  -display cocoa,gl=on \
  -virtio-gpu-gl,present=on \
  -device virtio-gpu-pci,gl=true \
  ...
```

## What's Included

- **QEMU system binaries**: qemu-system-x86_64, qemu-system-aarch64, qemu-system-arm, etc.
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

## License

GPL-2.0-or-later

## Upstream

- **[QEMU](https://www.qemu.org/)**: Generic and open source machine emulator and virtualizer
- **[virglrenderer](https://gitlab.freedesktop.org/virgl/virglrenderer)**: Virtual 3D GPU renderer (via [startergo/homebrew-virglrenderer](https://github.com/startergo/homebrew-virglrenderer))
- **[ANGLE](https://chromium.googlesource.com/angle/angle)**: OpenGL ES implementation for macOS (via [startergo/homebrew-angle](https://github.com/startergo/homebrew-angle))
- **[libepoxy](https://github.com/anholt/libepoxy)**: OpenGL function pointer management (via [startergo/homebrew-libepoxy](https://github.com/startergo/homebrew-libepoxy))
- **[LunarG Vulkan SDK](https://vulkan.lunarg.com/doc/sdk/1.4.335.1/mac/release_notes.html)**: Vulkan SDK for macOS (includes KosmicKrisp, a Vulkan-to-Metal layered driver for Apple Silicon, currently in alpha)

This tap builds against the latest upstream QEMU with macOS-specific optimizations for graphics acceleration.
