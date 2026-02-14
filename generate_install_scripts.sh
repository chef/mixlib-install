#!/bin/bash

#
# Script to generate Chef install scripts using mixlib-install
#
# Usage: ./generate_install_scripts.sh [options]
#
# Options:
#   -L, --license-key KEY  - Chef license key for commercial downloads
#                            (optional, uses CHEF_LICENSE_KEY env var if not provided)
#   -b, --base-url URL     - Base URL for package downloads (optional)
#   -p, --product NAME     - Product name (default: chef)
#   -c, --channel NAME     - Channel (default: stable)
#   -v, --version VER      - Product version (default: latest)
#   -o, --output DIR       - Output directory (default: current directory)
#   -h, --help             - Show this help message
#

set -e

# Default values
PRODUCT_NAME="chef"
CHANNEL="stable"
VERSION="latest"
OUTPUT_DIR="."
LICENSE_KEY=""
BASE_URL=""

# Parse command line arguments
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -L, --license-key KEY  Chef license key for commercial downloads"
    echo "                         (optional, uses CHEF_LICENSE_KEY env var if not provided)"
    echo "  -b, --base-url URL     Base URL for package downloads (optional)"
    echo "  -p, --product NAME     Product name (default: chef)"
    echo "  -c, --channel NAME     Channel: stable, current, or unstable (default: stable)"
    echo "  -v, --version VER      Product version (default: latest)"
    echo "  -o, --output DIR       Output directory (default: current directory)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -L my-license-key-123"
    echo "  $0 -L my-license-key-123 -p chef-workstation -v 24.2.1058"
    echo "  $0 -o /tmp/scripts -c current"
    echo "  $0 -b https://custom-repo.example.com"
    echo "  CHEF_LICENSE_KEY=my-key $0 -p chef-workstation"
    exit 0
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -L|--license-key)
            LICENSE_KEY="$2"
            shift 2
            ;;
        -b|--base-url)
            BASE_URL="$2"
            shift 2
            ;;
        -p|--product)
            PRODUCT_NAME="$2"
            shift 2
            ;;
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            show_usage
            ;;
    esac
done

# Use CHEF_LICENSE_KEY environment variable if license key not provided via option
if [ -z "$LICENSE_KEY" ] && [ -n "${CHEF_LICENSE_KEY:-}" ]; then
    LICENSE_KEY="$CHEF_LICENSE_KEY"
    echo "Using license key from CHEF_LICENSE_KEY environment variable"
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if mixlib-install gem is installed
echo "Checking for mixlib-install gem..."
if ! gem list -i mixlib-install > /dev/null 2>&1; then
    echo "mixlib-install gem not found. Installing..."
    gem build mixlib-install.gemspec
    gem install mixlib-install-*.gem
    echo "✓ mixlib-install gem installed successfully"
else
    echo "✓ mixlib-install gem is already installed"
fi

# Generate install.sh script for Linux/Unix
echo ""
echo "Generating install.sh for $PRODUCT_NAME (channel: $CHANNEL, version: $VERSION)..."

ruby -I "lib" -e "
require 'mixlib/install'

context = {}
context[:license_id] = '$LICENSE_KEY' unless '$LICENSE_KEY'.empty?
context[:base_url] = '$BASE_URL' unless '$BASE_URL'.empty?

script = Mixlib::Install.install_sh(context)

File.write('$OUTPUT_DIR/install.sh', script)
puts '✓ install.sh generated successfully'
"

# Make the script executable
chmod +x "$OUTPUT_DIR/install.sh"

# Generate install.ps1 script for Windows
echo ""
echo "Generating install.ps1 for $PRODUCT_NAME (channel: $CHANNEL, version: $VERSION)..."

ruby -I "lib" -e "
require 'mixlib/install'

context = {}
context[:license_id] = '$LICENSE_KEY' unless '$LICENSE_KEY'.empty?
context[:base_url] = '$BASE_URL' unless '$BASE_URL'.empty?

script = Mixlib::Install.install_ps1(context)

File.write('$OUTPUT_DIR/install.ps1', script)
puts '✓ install.ps1 generated successfully'
"

# Summary
echo ""
echo "================================================"
echo "Scripts generated successfully!"
echo "================================================"
echo "Product:       $PRODUCT_NAME"
echo "Channel:       $CHANNEL"
echo "Version:       $VERSION"
if [ -n "$LICENSE_KEY" ]; then
    echo "License Key:   ${LICENSE_KEY:0:10}..." # Show only first 10 chars
else
    echo "License Key:   Not provided"
fi
if [ -n "$BASE_URL" ]; then
    echo "Base URL:      $BASE_URL"
fi
echo ""
echo "Output files:"
echo "  - $OUTPUT_DIR/install.sh"
echo "  - $OUTPUT_DIR/install.ps1"
echo ""
if [ -n "$LICENSE_KEY" ]; then
    echo "The license key has been embedded in the generated scripts."
else
    echo "Note: No license key provided. Scripts will check for CHEF_LICENSE_KEY environment variable at runtime."
fi
echo "You can now use these scripts to install $PRODUCT_NAME on Linux/Unix and Windows systems."
