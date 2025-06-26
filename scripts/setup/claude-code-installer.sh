#!/bin/bash
# install-claude-code.sh - Claude Code インストールスクリプト
# 公式ドキュメント: https://docs.anthropic.com/ja/docs/claude-code/getting-started

set -euo pipefail

echo "========================================"
echo " Claude Code Installation Script"
echo "========================================"
echo ""

# 変数設定
CLAUDE_USER="${SUDO_USER:-$USER}"

# 1. 前提条件の確認
echo "Checking prerequisites..."

# Python 3.8以上の確認
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "Python version: $PYTHON_VERSION"

# 2. Claude Code のインストール
echo ""
echo "Installing Claude Code..."

# pip を使用したインストール（推奨方法）
pip3 install --user claude-code || {
    echo "Failed to install via pip. Trying alternative method..."
    
    # 仮想環境を使用したインストール
    python3 -m venv ~/.claude-code-env
    source ~/.claude-code-env/bin/activate
    pip install claude-code
    deactivate
    
    # 仮想環境用のラッパースクリプト作成
    cat > ~/.local/bin/claude-code << 'EOF'
#!/bin/bash
source ~/.claude-code-env/bin/activate
claude-code "$@"
deactivate
EOF
    chmod +x ~/.local/bin/claude-code
}

# 3. 環境変数の設定
echo ""
echo "Setting up environment..."

# .bashrc に追加（既に存在しない場合）
if ! grep -q "claude-code" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Claude Code settings
export PATH="$PATH:$HOME/.local/bin"

# Claude Code API key (set your key here)
# export ANTHROPIC_API_KEY="your-api-key-here"

# Claude Code aliases
alias claude="claude-code"
alias cc="claude-code"

# Enable completion if available
if command -v claude-code &> /dev/null; then
    eval "$(claude-code --completion-script bash 2>/dev/null || true)"
fi
EOF
fi

# 4. 設定ディレクトリの作成
echo ""
echo "Creating configuration directory..."
mkdir -p ~/.config/claude-code

# 5. 初期設定ファイルの作成
if [ ! -f ~/.config/claude-code/config.yaml ]; then
    cat > ~/.config/claude-code/config.yaml << 'EOF'
# Claude Code Configuration
# Documentation: https://docs.anthropic.com/ja/docs/claude-code/getting-started

# API Configuration
api:
  # Your API key (can also be set via ANTHROPIC_API_KEY environment variable)
  # key: "sk-ant-..."
  
  # API endpoint (default: https://api.anthropic.com)
  # endpoint: "https://api.anthropic.com"

# Default model settings
defaults:
  # Available models: claude-3-opus-20240229, claude-3-sonnet-20240229, claude-3-haiku-20240307
  model: "claude-3-opus-20240229"
  
  # Maximum tokens in response
  max_tokens: 4096
  
  # Temperature (0.0 - 1.0)
  temperature: 0.7
  
  # System prompt
  # system: "You are a helpful AI assistant."

# Project settings
project:
  # File patterns to ignore
  ignore_patterns:
    - "*.pyc"
    - "__pycache__"
    - ".git"
    - ".venv"
    - "node_modules"
    - "*.log"
  
  # Maximum file size to process (in bytes)
  max_file_size: 1048576  # 1MB

# Output settings
output:
  # Format: plain, markdown, json
  format: "markdown"
  
  # Syntax highlighting
  highlight: true
  
  # Line wrapping
  wrap: 80

# Editor integration
editor:
  # Command to open files
  command: "${EDITOR:-vim}"
  
  # Temporary file directory
  temp_dir: "/tmp/claude-code"

# Logging
logging:
  # Log level: debug, info, warning, error
  level: "info"
  
  # Log file location
  # file: "~/.claude-code/claude-code.log"
EOF
fi

# 6. APIキー設定の確認と案内
echo ""
echo "========================================"
echo " Setup Instructions"
echo "========================================"
echo ""
echo "Claude Code has been installed successfully!"
echo ""
echo "Next steps:"
echo ""
echo "1. Get your API key:"
echo "   Visit: https://console.anthropic.com/"
echo "   Create an account and generate an API key"
echo ""
echo "2. Set your API key (choose one method):"
echo ""
echo "   Method A - Environment variable (recommended):"
echo "   export ANTHROPIC_API_KEY='your-api-key-here'"
echo "   echo 'export ANTHROPIC_API_KEY=\"your-api-key-here\"' >> ~/.bashrc"
echo ""
echo "   Method B - Interactive login:"
echo "   claude-code auth login"
echo ""
echo "   Method C - Config file:"
echo "   Edit ~/.config/claude-code/config.yaml"
echo "   Add your key under api: key: 'your-api-key-here'"
echo ""
echo "3. Reload your shell configuration:"
echo "   source ~/.bashrc"
echo ""
echo "4. Verify installation:"
echo "   claude-code --version"
echo "   claude-code --help"
echo ""
echo "5. Test Claude Code:"
echo "   echo 'What is recursion?' | claude-code"
echo "   claude-code 'Explain quantum computing in simple terms'"
echo ""
echo "Common commands:"
echo "  claude-code <prompt>           - Send a prompt to Claude"
echo "  claude-code -f file.py        - Analyze a file"
echo "  claude-code -p project/       - Analyze a project directory"
echo "  claude-code -m claude-3-haiku - Use a different model"
echo "  claude-code --chat            - Start interactive chat mode"
echo ""
echo "For more information:"
echo "https://docs.anthropic.com/ja/docs/claude-code/getting-started"
echo ""

# 7. インストール確認
if command -v claude-code &> /dev/null; then
    echo "✓ Claude Code is available in PATH"
    echo "  Location: $(which claude-code)"
    
    # バージョン確認を試みる
    if claude-code --version &> /dev/null; then
        echo "  Version: $(claude-code --version)"
    fi
else
    echo "⚠ Claude Code is not in PATH yet."
    echo "  Please run: source ~/.bashrc"
    echo "  Or start a new terminal session."
fi

echo ""
echo "Installation complete!"