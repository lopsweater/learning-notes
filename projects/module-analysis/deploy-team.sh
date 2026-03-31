#!/bin/bash

# Claude Code Module Analysis Plugin - Team Deployment Script
# Usage: ./deploy-team.sh [install|update|uninstall]

set -e

PLUGIN_NAME="module-analysis"
PLUGIN_DIR="/root/.openclaw/workspace/skills/module-analysis"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
COMMANDS_DIR="$CLAUDE_DIR/commands"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

install() {
    log_info "Installing $PLUGIN_NAME plugin..."

    # Create directories
    mkdir -p "$PLUGINS_DIR"
    mkdir -p "$COMMANDS_DIR"

    # Copy skill
    if [ -f "$PLUGIN_DIR/SKILL.md" ]; then
        mkdir -p "$PLUGINS_DIR/$PLUGIN_NAME"
        cp "$PLUGIN_DIR/SKILL.md" "$PLUGINS_DIR/$PLUGIN_NAME/"
        log_success "Copied SKILL.md"
    else
        log_error "SKILL.md not found"
        exit 1
    fi

    # Copy command
    if [ -f "$PLUGIN_DIR/commands/ge-module-analysis.md" ]; then
        cp "$PLUGIN_DIR/commands/ge-module-analysis.md" "$COMMANDS_DIR/"
        log_success "Copied command: ge-module-analysis"
    else
        log_error "Command file not found"
        exit 1
    fi

    # Copy additional files
    if [ -d "$PLUGIN_DIR/templates" ]; then
        cp -r "$PLUGIN_DIR/templates" "$PLUGINS_DIR/$PLUGIN_NAME/"
        log_success "Copied templates"
    fi

    if [ -d "$PLUGIN_DIR/references" ]; then
        cp -r "$PLUGIN_DIR/references" "$PLUGINS_DIR/$PLUGIN_NAME/"
        log_success "Copied references"
    fi

    # Copy package.json for metadata
    if [ -f "$PLUGIN_DIR/package.json" ]; then
        cp "$PLUGIN_DIR/package.json" "$PLUGINS_DIR/$PLUGIN_NAME/"
    fi

    log_success "✅ $PLUGIN_NAME plugin installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Claude Code: claude"
    echo "  2. Test command: /ge-module-analysis --help"
    echo ""
}

update() {
    log_info "Updating $PLUGIN_NAME plugin..."

    # Remove old version
    if [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"
    fi
    if [ -f "$COMMANDS_DIR/ge-module-analysis.md" ]; then
        rm "$COMMANDS_DIR/ge-module-analysis.md"
    fi

    # Install new version
    install

    log_success "✅ $PLUGIN_NAME plugin updated!"
}

uninstall() {
    log_info "Uninstalling $PLUGIN_NAME plugin..."

    # Remove plugin files
    if [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"
        log_success "Removed plugin directory"
    fi

    if [ -f "$COMMANDS_DIR/ge-module-analysis.md" ]; then
        rm "$COMMANDS_DIR/ge-module-analysis.md"
        log_success "Removed command"
    fi

    log_success "✅ $PLUGIN_NAME plugin uninstalled"
}

verify() {
    log_info "Verifying installation..."

    local all_good=true

    # Check skill file
    if [ -f "$PLUGINS_DIR/$PLUGIN_NAME/SKILL.md" ]; then
        log_success "✓ SKILL.md exists"
    else
        log_error "✗ SKILL.md missing"
        all_good=false
    fi

    # Check command file
    if [ -f "$COMMANDS_DIR/ge-module-analysis.md" ]; then
        log_success "✓ Command exists"
    else
        log_error "✗ Command missing"
        all_good=false
    fi

    # Check templates
    if [ -d "$PLUGINS_DIR/$PLUGIN_NAME/templates" ]; then
        log_success "✓ Templates exist"
    else
        log_error "✗ Templates missing"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        log_success "✅ All files verified successfully!"
        return 0
    else
        log_error "❌ Verification failed"
        return 1
    fi
}

# Main
case "${1:-install}" in
    install)
        install
        ;;
    update)
        update
        ;;
    uninstall)
        uninstall
        ;;
    verify)
        verify
        ;;
    *)
        echo "Usage: $0 {install|update|uninstall|verify}"
        exit 1
        ;;
esac
