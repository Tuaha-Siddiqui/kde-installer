#!/bin/bash

# KDE Plasma Git Build Script for Kubuntu
# This script builds KDE Plasma from source without using dpkg

set -euo pipefail

# Configuration
KDESRC_DIR="$HOME/kde"
INSTALL_PREFIX="$KDESRC_DIR/install"
BUILD_THREADS=$(nproc --all)

# Error handling function
handle_error() {
    echo -e "\nERROR: Build failed at line $1"
    echo "Check the logs in $KDESRC_DIR/build/log/"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Create required directories
create_dirs() {
    echo "Creating directory structure..."
    mkdir -p "$KDESRC_DIR"/{src,build,install,log} || {
        echo "Failed to create directories"
        exit 1
    }
}

# Install basic build dependencies
install_deps() {
    echo "Checking for basic build tools..."

    local required_tools=(
        git cmake g++ make extra-cmake-modules 
        ninja-build gettext libffi-dev libxml2-dev
        libxslt1-dev libjpeg-dev libpng-dev
        libfreetype6-dev libsqlite3-dev
        libx11-dev libxcb1-dev libxext-dev
        libxfixes-dev libxrender-dev libxrandr-dev
        libxdamage-dev libxcomposite-dev libxshmfence-dev
        libxkbfile-dev libxcursor-dev libxinerama-dev
        libfontconfig1-dev libglib2.0-dev libinput-dev
        libwayland-dev libegl1-mesa-dev libgbm-dev
        libsystemd-dev libdrm-dev libudev-dev
        libpulse-dev libssl-dev libicu-dev
        libavcodec-dev libavformat-dev libavutil-dev
        libswscale-dev libswresample-dev
    )

    if ! command -v apt-get >/dev/null 2>&1; then
        echo "Warning: apt-get not found. You'll need to install dependencies manually."
        return
    fi

    echo "Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y "${required_tools[@]}" || {
        echo "Failed to install dependencies"
        exit 1
    }
}

# Setup environment
setup_environment() {
    echo "Setting up build environment..."

    cat << EOF >> "$HOME/.bashrc"
# KDE Build Environment
export KDESRC_BUILD="$KDESRC_DIR"
export PATH="$INSTALL_PREFIX/bin:\$PATH"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:\$XDG_DATA_DIRS"
export QT_PLUGIN_PATH="$INSTALL_PREFIX/lib/plugins:\$QT_PLUGIN_PATH"
export QML2_IMPORT_PATH="$INSTALL_PREFIX/lib/qml:\$QML2_IMPORT_PATH"
EOF

    source "$HOME/.bashrc"
}

# Clone kdesrc-build
get_kdesrc_build() {
    echo "Cloning kdesrc-build..."
    if [ ! -d "$KDESRC_DIR/kdesrc-build" ]; then
        git clone https://invent.kde.org/sdk/kdesrc-build.git "$KDESRC_DIR/kdesrc-build" || {
            echo "Failed to clone kdesrc-build"
            exit 1
        }
    else
        echo "kdesrc-build already exists, updating..."
        git -C "$KDESRC_DIR/kdesrc-build" pull || {
            echo "Failed to update kdesrc-build"
            exit 1
        }
    fi
}

# Configure kdesrc-build
configure_build() {
    echo "Configuring kdesrc-build..."

    cat > "$HOME/.config/kdesrc-buildrc" << EOF
global
    # Install directory
    kdedir $INSTALL_PREFIX
    
    # Directory for downloaded source code
    source-dir $KDESRC_DIR/src
    
    # Directory to build each module
    build-dir $KDESRC_DIR/build
    
    # Number of jobs for make
    make-options -j$BUILD_THREADS
    
    # Use Ninja instead of Make
    cmake-generator Ninja
    
    # Stop on failure
    stop-on-failure true
end global

include /kf5-qt5
EOF
}

# Build KDE components
build_kde() {
    echo "Starting KDE build process..."
    cd "$KDESRC_DIR/kdesrc-build"
    
    # Build frameworks first
    echo "Building KDE Frameworks..."
    ./kdesrc-build frameworks > "$KDESRC_DIR/log/frameworks.log" 2>&1
    
    # Then Plasma
    echo "Building Plasma..."
    ./kdesrc-build plasma-workspace plasma-desktop > "$KDESRC_DIR/log/plasma.log" 2>&1
    
    # Optional: Applications
    read -rp "Build KDE Applications as well? (y/N) " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        echo "Building KDE Applications..."
        ./kdesrc-build kde-applications > "$KDESRC_DIR/log/applications.log" 2>&1
    fi
}

# Main execution
main() {
    echo "KDE Plasma Git Build Script for Kubuntu"
    echo "======================================"
    
    create_dirs
    install_deps
    setup_environment
    get_kdesrc_build
    configure_build
    build_kde
    
    echo -e "\nBuild completed successfully!"
    echo "To run your newly built Plasma session:"
    echo "For X11: startplasma-x11"
    echo "For Wayland: startplasma-wayland"
    echo "You may need to log out and select the custom session from your display manager."
}

main