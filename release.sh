#!/bin/bash
# Release automation script for Claude Tools
# Handles version bumping, building, and distribution

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CURRENT_VERSION=$(grep '"version"' package.json | sed 's/.*"version": "\(.*\)".*/\1/')

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Help function
show_help() {
    echo "Usage: $0 <version-type> [options]"
    echo ""
    echo "Version types:"
    echo "  patch    - Bug fixes (1.0.0 -> 1.0.1)"
    echo "  minor    - New features (1.0.0 -> 1.1.0)"
    echo "  major    - Breaking changes (1.0.0 -> 2.0.0)"
    echo "  <version> - Specific version (e.g., 1.2.3)"
    echo ""
    echo "Options:"
    echo "  --dry-run    - Show what would be done without making changes"
    echo "  --no-build   - Skip building packages"
    echo "  --no-git     - Skip git operations"
    echo "  --help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 patch              # Release patch version"
    echo "  $0 minor --dry-run    # Show minor version release plan"
    echo "  $0 1.2.3              # Release specific version"
}

# Parse arguments
VERSION_TYPE=""
DRY_RUN=false
NO_BUILD=false
NO_GIT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        patch|minor|major)
            VERSION_TYPE="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --no-git)
            NO_GIT=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        [0-9]*)
            VERSION_TYPE="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "$VERSION_TYPE" ]; then
    echo "Error: Version type is required"
    show_help
    exit 1
fi

# Calculate new version
calculate_new_version() {
    local current="$1"
    local type="$2"
    
    if [[ "$type" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$type"
        return
    fi
    
    IFS='.' read -r major minor patch <<< "$current"
    
    case "$type" in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "$major.$((minor + 1)).0"
            ;;
        patch)
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            echo "Invalid version type: $type" >&2
            exit 1
            ;;
    esac
}

NEW_VERSION=$(calculate_new_version "$CURRENT_VERSION" "$VERSION_TYPE")

echo -e "${BLUE}🚀 Claude Tools Release Automation${NC}"
echo -e "${BLUE}Current version: $CURRENT_VERSION${NC}"
echo -e "${BLUE}New version: $NEW_VERSION${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🧪 DRY RUN MODE - No changes will be made${NC}"
    echo ""
fi

# Pre-release checks
echo -e "${YELLOW}🔍 Running pre-release checks...${NC}"

# Check if git is clean
if [ "$NO_GIT" = false ] && [ "$DRY_RUN" = false ]; then
    if ! git diff --quiet; then
        echo -e "${RED}❌ Git working directory is not clean${NC}"
        echo "Please commit or stash your changes first"
        exit 1
    fi
fi

# Validate package readiness
echo "Validating package readiness..."
if [ "$DRY_RUN" = false ]; then
    if ! ./validate-package-readiness.sh; then
        echo -e "${RED}❌ Package validation failed${NC}"
        exit 1
    fi
fi

# Run tests
echo "Running tests..."
if [ "$DRY_RUN" = false ]; then
    if ! npm test; then
        echo -e "${RED}❌ Tests failed${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Pre-release checks passed${NC}"

# Update version in files
echo -e "${YELLOW}📝 Updating version in files...${NC}"

update_version_in_file() {
    local file="$1"
    local old_version="$2"
    local new_version="$3"
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would update $file: $old_version -> $new_version"
        return
    fi
    
    if [ -f "$file" ]; then
        sed -i '' "s/\"version\": \"$old_version\"/\"version\": \"$new_version\"/g" "$file"
        echo "Updated $file"
    fi
}

update_version_in_file "package.json" "$CURRENT_VERSION" "$NEW_VERSION"
update_version_in_file "claude-tools.rb" "$CURRENT_VERSION" "$NEW_VERSION"

# Update README version references
if [ "$DRY_RUN" = false ]; then
    if [ -f "README.md" ]; then
        sed -i '' "s/v$CURRENT_VERSION/v$NEW_VERSION/g" README.md
        echo "Updated README.md"
    fi
fi

# Build packages
if [ "$NO_BUILD" = false ]; then
    echo -e "${YELLOW}📦 Building packages...${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would build macOS PKG package"
        echo "Would update Homebrew formula"
        echo "Would prepare NPM package"
    else
        # Build macOS PKG
        echo "Building macOS PKG..."
        ./build-pkg.sh
        
        # Update Homebrew formula with new SHA
        if [ -f "dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg.sha256" ]; then
            PKG_SHA=$(cat "dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg.sha256" | cut -d' ' -f1)
            sed -i '' "s/PLACEHOLDER_SHA256/$PKG_SHA/g" claude-tools.rb
            echo "Updated Homebrew formula with SHA256"
        fi
        
        echo -e "${GREEN}✅ Packages built successfully${NC}"
    fi
fi

# Git operations
if [ "$NO_GIT" = false ]; then
    echo -e "${YELLOW}📋 Git operations...${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would create git commit with version $NEW_VERSION"
        echo "Would create git tag v$NEW_VERSION"
        echo "Would push to origin"
    else
        # Commit changes
        git add .
        git commit -m "release: v$NEW_VERSION

- Version bump to $NEW_VERSION
- Updated package manifests
- Built distribution packages
- Updated documentation

🚀 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        # Create tag
        git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
        
        # Push to origin
        git push origin main
        git push origin "v$NEW_VERSION"
        
        echo -e "${GREEN}✅ Git operations completed${NC}"
    fi
fi

# Generate release notes
echo -e "${YELLOW}📋 Generating release notes...${NC}"

RELEASE_NOTES_FILE="RELEASE_NOTES_v$NEW_VERSION.md"

if [ "$DRY_RUN" = false ]; then
    cat > "$RELEASE_NOTES_FILE" << EOF
# Claude Tools v$NEW_VERSION Release Notes

**Release Date:** $(date '+%Y-%m-%d')  
**Version:** v$NEW_VERSION  
**Previous Version:** v$CURRENT_VERSION  

## 🚀 What's New

### Features
- Enhanced Claude Code workflow system
- Git worktree management for parallel development
- Design iteration engine with 4 UI agents
- IDE integration with @ file references
- Audio notification system
- Intelligent clipboard utilities
- Model management system
- Safe mode with permission caching

### Improvements
- Performance optimizations
- Enhanced error handling
- Better user experience
- Comprehensive testing suite

## 📦 Installation

### macOS PKG
\`\`\`bash
# Download and install
curl -L https://github.com/angelor888/DR-IT-ClaudeSDKSetup/releases/download/v$NEW_VERSION/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg -o claude-tools.pkg
sudo installer -pkg claude-tools.pkg -target /
claude-workflow-install
\`\`\`

### Homebrew
\`\`\`bash
# Add tap and install
brew tap angelor888/claude-tools
brew install claude-tools
claude-workflow-install
\`\`\`

### NPM
\`\`\`bash
# Install globally
npm install -g @dr-it/claude-sdk-setup
claude-workflow-install
\`\`\`

## 🔧 System Requirements

- macOS 10.15 or later
- Git (Xcode Command Line Tools)
- Homebrew package manager
- Node.js 18+ (recommended)
- Docker Desktop (for MCP services)

## 🆘 Support

- **Documentation:** https://github.com/angelor888/DR-IT-ClaudeSDKSetup
- **Issues:** https://github.com/angelor888/DR-IT-ClaudeSDKSetup/issues
- **Testing:** Run \`claude-workflow-test all\` to validate installation

## 🔐 Checksums

- **macOS PKG:** \`$(cat "dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg.sha256" 2>/dev/null || echo "Will be generated")\`

---

🚀 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF

    echo "Release notes generated: $RELEASE_NOTES_FILE"
fi

# Summary
echo ""
echo -e "${GREEN}🎉 Release automation completed!${NC}"
echo ""
echo -e "${BLUE}📊 Release Summary:${NC}"
echo "  Version: v$NEW_VERSION"
echo "  Previous: v$CURRENT_VERSION"
echo "  Type: $VERSION_TYPE"
echo ""

if [ "$DRY_RUN" = false ]; then
    echo -e "${BLUE}📦 Generated Files:${NC}"
    echo "  - dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg"
    echo "  - dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg.sha256"
    echo "  - $RELEASE_NOTES_FILE"
    echo "  - Updated claude-tools.rb"
    echo ""
    
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "  1. Test the package: sudo installer -pkg dist/DR-IT-ClaudeSDKSetup-v$NEW_VERSION.pkg -target /"
    echo "  2. Create GitHub release with generated assets"
    echo "  3. Update Homebrew tap repository"
    echo "  4. Publish to NPM (if configured)"
    echo ""
fi

echo -e "${GREEN}✅ All done!${NC}"