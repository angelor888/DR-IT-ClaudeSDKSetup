#!/bin/bash
# Build macOS PKG installer for Claude Tools
# Creates a signed, distributable macOS package

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VERSION=$(grep '"version"' package.json | sed 's/.*"version": "\(.*\)".*/\1/')
PACKAGE_NAME="DR-IT-ClaudeSDKSetup"
PACKAGE_ID="com.duetright.claude-tools"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}📦 Building macOS PKG for Claude Tools v$VERSION${NC}"

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Create package structure
echo -e "${YELLOW}🏗️  Creating package structure...${NC}"
PACKAGE_ROOT="$BUILD_DIR/package_root"
mkdir -p "$PACKAGE_ROOT/usr/local/lib/claude-tools"
mkdir -p "$PACKAGE_ROOT/usr/local/bin"

# Copy project files
echo -e "${YELLOW}📁 Copying project files...${NC}"
cp -r claude-config "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp -r scripts "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp -r configs "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp -r docs "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp install.sh "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp uninstall.sh "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp README.md "$PACKAGE_ROOT/usr/local/lib/claude-tools/"
cp package.json "$PACKAGE_ROOT/usr/local/lib/claude-tools/"

# Create symlinks in /usr/local/bin
echo -e "${YELLOW}🔗 Creating symlinks...${NC}"
ln -sf "/usr/local/lib/claude-tools/install.sh" "$PACKAGE_ROOT/usr/local/bin/claude-workflow-install"
ln -sf "/usr/local/lib/claude-tools/uninstall.sh" "$PACKAGE_ROOT/usr/local/bin/claude-workflow-uninstall"

# Make scripts executable
echo -e "${YELLOW}⚙️  Setting permissions...${NC}"
find "$PACKAGE_ROOT/usr/local/lib/claude-tools" -name "*.sh" -exec chmod +x {} \;
chmod +x "$PACKAGE_ROOT/usr/local/bin/claude-workflow-install"
chmod +x "$PACKAGE_ROOT/usr/local/bin/claude-workflow-uninstall"

# Create scripts directory
SCRIPTS_DIR="$BUILD_DIR/scripts"
mkdir -p "$SCRIPTS_DIR"

# Create preinstall script
cat > "$SCRIPTS_DIR/preinstall" << 'EOF'
#!/bin/bash
# Pre-installation script

set -euo pipefail

echo "🔍 Checking system requirements..."

# Check macOS version
if ! sw_vers -productVersion | grep -q "^1[0-9]\|^[2-9][0-9]"; then
    echo "❌ macOS 10.0 or later required"
    exit 1
fi

# Check for required tools
if ! command -v git &> /dev/null; then
    echo "❌ Git is required. Please install Xcode Command Line Tools"
    exit 1
fi

if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is required. Please install from https://brew.sh"
    exit 1
fi

echo "✅ System requirements met"
EOF

# Create postinstall script
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash
# Post-installation script

set -euo pipefail

echo ""
echo "🚀 Claude Tools installed successfully!"
echo ""
echo "To complete the installation:"
echo "  1. Run: claude-workflow-install"
echo "  2. Follow the setup wizard"
echo "  3. Restart your terminal"
echo ""
echo "Quick start commands:"
echo "  claude-workflow-install     # Complete installation"
echo "  cwt-create feature-name     # Create git worktree"
echo "  cdesign 'UI brief'          # Generate design iterations"
echo "  claude-mode model opus      # Switch to Claude Opus"
echo ""
echo "Documentation: https://github.com/angelor888/DR-IT-ClaudeSDKSetup"
echo ""
EOF

# Create preremove script
cat > "$SCRIPTS_DIR/preremove" << 'EOF'
#!/bin/bash
# Pre-removal script

set -euo pipefail

echo "🧹 Preparing to remove Claude Tools..."

# Run uninstaller if available
if [ -x "/usr/local/lib/claude-tools/uninstall.sh" ]; then
    echo "Running uninstaller..."
    /usr/local/lib/claude-tools/uninstall.sh --package-removal
fi

echo "✅ Preparation complete"
EOF

# Make scripts executable
chmod +x "$SCRIPTS_DIR"/*

# Create Distribution.xml
cat > "$BUILD_DIR/Distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Claude Tools v$VERSION</title>
    <organization>com.duetright</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false"/>
    
    <welcome file="welcome.html"/>
    <license file="license.txt"/>
    <readme file="readme.html"/>
    
    <pkg-ref id="$PACKAGE_ID"/>
    <options customize="never" require-scripts="false"/>
    
    <choices-outline>
        <line choice="default">
            <line choice="$PACKAGE_ID"/>
        </line>
    </choices-outline>
    
    <choice id="default"/>
    <choice id="$PACKAGE_ID" visible="false">
        <pkg-ref id="$PACKAGE_ID"/>
    </choice>
    
    <pkg-ref id="$PACKAGE_ID" version="$VERSION" onConclusion="none">ClaudeTools.pkg</pkg-ref>
</installer-gui-script>
EOF

# Create welcome.html
cat > "$BUILD_DIR/welcome.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Welcome to Claude Tools</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { color: #007AFF; }
        .feature { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🚀 Welcome to Claude Tools v$VERSION</h1>
    <p>This installer will set up the Claude Code advanced workflow system on your Mac.</p>
    
    <h2>🌟 Features</h2>
    <div class="feature">
        <strong>🌳 Git Worktree System</strong><br>
        Parallel development isolation for conflict-free multitasking
    </div>
    <div class="feature">
        <strong>🎨 Design Iteration Engine</strong><br>
        4 parallel UI design agents for rapid prototyping
    </div>
    <div class="feature">
        <strong>🔧 IDE Integration</strong><br>
        Seamless integration with VS Code, IntelliJ, and other IDEs
    </div>
    <div class="feature">
        <strong>🔊 Audio Notifications</strong><br>
        Project-specific sound themes and voice synthesis
    </div>
    
    <h2>📋 System Requirements</h2>
    <ul>
        <li>macOS 10.15 or later</li>
        <li>Git (Xcode Command Line Tools)</li>
        <li>Homebrew package manager</li>
        <li>Node.js 18+ (optional)</li>
    </ul>
    
    <p><strong>Note:</strong> After installation, run <code>claude-workflow-install</code> to complete the setup.</p>
</body>
</html>
EOF

# Create license.txt
cat > "$BUILD_DIR/license.txt" << EOF
PROPRIETARY LICENSE

Copyright (c) 2025 DuetRight IT Team

This software is proprietary and confidential. Unauthorized copying, distribution, or modification is strictly prohibited.

By installing this software, you agree to:
1. Use this software solely for authorized purposes
2. Not distribute or share this software without permission
3. Maintain the confidentiality of this software
4. Comply with all applicable laws and regulations

This software is provided "as is" without warranty of any kind.
EOF

# Create readme.html
cat > "$BUILD_DIR/readme.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Claude Tools - Installation Guide</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        h1 { color: #007AFF; }
        code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
        .step { margin: 15px 0; padding: 15px; background: #f8f9fa; border-left: 4px solid #007AFF; }
    </style>
</head>
<body>
    <h1>📖 Installation Guide</h1>
    
    <h2>🚀 Post-Installation Steps</h2>
    <div class="step">
        <strong>Step 1:</strong> Complete the installation<br>
        <code>claude-workflow-install</code>
    </div>
    
    <div class="step">
        <strong>Step 2:</strong> Configure your environment<br>
        <code>cp ~/.config/claude/environment.template ~/.config/claude/environment</code><br>
        Edit the environment file with your API keys and settings.
    </div>
    
    <div class="step">
        <strong>Step 3:</strong> Test the installation<br>
        <code>claude-workflow-test all</code>
    </div>
    
    <div class="step">
        <strong>Step 4:</strong> Add shell integration<br>
        <code>echo 'source ~/.config/claude/shell-integration.sh' >> ~/.zshrc</code><br>
        <code>source ~/.zshrc</code>
    </div>
    
    <h2>💡 Quick Start Commands</h2>
    <ul>
        <li><code>cwt-create feature-name</code> - Create git worktree</li>
        <li><code>cdesign "UI brief"</code> - Generate design iterations</li>
        <li><code>claude-mode model opus</code> - Switch to Claude Opus</li>
        <li><code>claude-help</code> - Show all available commands</li>
    </ul>
    
    <h2>📚 Documentation</h2>
    <p>Complete documentation available at:</p>
    <ul>
        <li><a href="https://github.com/angelor888/DR-IT-ClaudeSDKSetup">GitHub Repository</a></li>
        <li><code>~/.config/claude/SETUP.md</code> - Setup guide</li>
        <li><code>~/.config/claude/IMPLEMENTATION_REPORT.md</code> - Technical details</li>
    </ul>
    
    <h2>🆘 Support</h2>
    <p>For issues and questions:</p>
    <ul>
        <li>GitHub Issues: <a href="https://github.com/angelor888/DR-IT-ClaudeSDKSetup/issues">Report Issues</a></li>
        <li>Run diagnostics: <code>claude-workflow-test all</code></li>
        <li>Check logs: <code>tail -f ~/.config/claude/logs/setup-*.log</code></li>
    </ul>
</body>
</html>
EOF

# Build the component package
echo -e "${YELLOW}📦 Building component package...${NC}"
pkgbuild --root "$PACKAGE_ROOT" \
         --identifier "$PACKAGE_ID" \
         --version "$VERSION" \
         --scripts "$SCRIPTS_DIR" \
         "$BUILD_DIR/ClaudeTools.pkg"

# Build the final installer
echo -e "${YELLOW}🏗️  Building final installer...${NC}"
productbuild --distribution "$BUILD_DIR/Distribution.xml" \
             --package-path "$BUILD_DIR" \
             --resources "$BUILD_DIR" \
             "$DIST_DIR/$PACKAGE_NAME-v$VERSION.pkg"

# Generate SHA256 checksum
echo -e "${YELLOW}🔐 Generating checksums...${NC}"
cd "$DIST_DIR"
shasum -a 256 "$PACKAGE_NAME-v$VERSION.pkg" > "$PACKAGE_NAME-v$VERSION.pkg.sha256"

echo -e "${GREEN}✅ Package built successfully!${NC}"
echo -e "${BLUE}📦 Package: $DIST_DIR/$PACKAGE_NAME-v$VERSION.pkg${NC}"
echo -e "${BLUE}🔐 Checksum: $DIST_DIR/$PACKAGE_NAME-v$VERSION.pkg.sha256${NC}"
echo -e "${BLUE}📏 Size: $(du -h "$PACKAGE_NAME-v$VERSION.pkg" | cut -f1)${NC}"

# Display installation instructions
echo ""
echo -e "${YELLOW}📋 Installation Instructions:${NC}"
echo "1. Double-click the .pkg file to install"
echo "2. Follow the installer wizard"
echo "3. Run: claude-workflow-install"
echo "4. Complete the setup process"
echo ""
echo -e "${YELLOW}🧪 Testing:${NC}"
echo "installer -pkg \"$DIST_DIR/$PACKAGE_NAME-v$VERSION.pkg\" -target /"
echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"