#!/bin/bash

# ==============================================
# INSTALL KDE PLASMA 5.18.8 FROM SOURCE (UBUNTU)
# ==============================================
# This script automates the download, compilation, and installation of Plasma 5.18.8.
# WARNING: This may conflict with existing desktop environments. Use at your own risk.

set -e  # Exit on error

# --- Step 1: Install Dependencies ---
echo "[INFO] Installing build dependencies..."
sudo apt update
sudo apt install -y \
    build-essential cmake extra-cmake-modules qtbase5-dev \
    libkf5plasma-dev libkf5kio-dev libkf5activities-dev \
    libkf5declarative-dev libkf5xmlgui-dev libkf5notifications-dev \
    libkf5globalaccel-dev libkf5configwidgets-dev libkf5wayland-dev \
    libkf5guiaddons-dev libkf5dbusaddons-dev gettext ninja-build

# --- Step 2: Download Plasma 5.18.8 Source ---
WORKDIR="$HOME/plasma-build"
mkdir -p "$WORKDIR" && cd "$WORKDIR"

echo "[INFO] Downloading Plasma 5.18.8 source..."
wget -q --show-progress https://download.kde.org/Attic/plasma/5.18.8/plasma-desktop-5.18.8.tar.xz
tar -xf plasma-desktop-5.18.8.tar.xz
cd plasma-desktop-5.18.8

# --- Step 3: Configure and Compile ---
mkdir -p build && cd build
echo "[INFO] Running CMake..."
cmake -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      -GNinja .. 2>&1 | tee cmake.log

if [ ! -f "Makefile" ] && [ ! -f "build.ninja" ]; then
    echo "[ERROR] CMake failed to generate build files. Check 'cmake.log'."
    exit 1
fi

echo "[INFO] Compiling Plasma (this may take a while)..."
ninja -j$(nproc) 2>&1 | tee build.log

# --- Step 4: Install ---
echo "[INFO] Installing Plasma..."
sudo ninja install 2>&1 | tee install.log

# --- Step 5: Clean Up ---
echo "[INFO] Cleaning up..."
cd "$WORKDIR"
rm -rf plasma-desktop-5.18.8*

# --- Step 6: Restart Plasma (if running) ---
if pgrep -x "plasmashell" >/dev/null; then
    echo "[INFO] Restarting Plasma..."
    kquitapp5 plasmashell || true
    kstart5 plasmashell
else
    echo "[INFO] Log out and select Plasma from your display manager to start it."
fi

echo "[SUCCESS] Plasma 5.18.8 installed!"
