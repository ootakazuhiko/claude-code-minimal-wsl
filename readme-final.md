# Minimal Claude Workspaces

<div align="center">

![WSL2](https://img.shields.io/badge/WSL2-Ubuntu%2022.04-orange)
![Podman](https://img.shields.io/badge/Podman-Rootless-blue)
![Size](https://img.shields.io/badge/Size-~500MB-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

**Claude Code向けに最適化された複数の独立WSLインスタンスを管理し、各インスタンスでPodmanによるコンテナ開発環境を提供するツール**

*A tool for managing multiple independent WSL instances optimized for Claude Code, providing Podman container development environments in each instance*

</div>

## 📝 概要 / Overview

本プロジェクトは、Windows上で複数のClaude Code開発環境を完全に独立した形で実行するためのツールです。各開発環境は：

- **独立したWSL2インスタンス**上で動作（ファイルシステム・プロセス・ネットワークが完全分離）
- **Rootless Podman**による安全なコンテナ実行環境を内蔵
- **最小構成Ubuntu**（~500MB）により軽量で高速な起動を実現
- **PowerShellスクリプト**による統合管理で簡単操作

開発者は各プロジェクトごとに完全に独立した環境を持ち、他のプロジェクトへの影響を心配することなく開発・実験が可能です。

## ✨ Key Concepts

- **🤖 Multiple Claude Code Instances** - Run independent Claude Code environments on the same Windows machine
- **📦 Podman Isolation** - Each instance has its own rootless Podman environment with separate network namespaces
- **🪶 Minimal Footprint** - ~500MB Ubuntu base (vs 1.5GB standard) with unnecessary packages removed
- **🔒 Complete Isolation** - Network, storage, and process separation between instances

## 🚀 Features

- **Multiple WSL Instances**: Create and manage multiple isolated Ubuntu 22.04 instances
- **Minimal Base Image**: Optimized Ubuntu image with only essential packages
- **Podman Integration**: Rootless container runtime pre-configured in each instance
- **Resource Management**: Hierarchical resource limits (WSL → Podman → Containers)
- **Network Isolation**: Each instance has its own network namespace (10.101.x.x, 10.102.x.x, etc.)
- **Cloudflare Tunnel Support**: Built-in integration for external access
- **Windows Integration**: PowerShell scripts for seamless management

## 📋 Requirements

- Windows 10/11 with WSL2 enabled
- PowerShell 5.1 or later
- 8GB+ RAM recommended
- 20GB+ free disk space
- Administrator privileges for initial setup

## 🔧 Quick Start

```powershell
# Clone the repository
git clone https://github.com/YOUR_USERNAME/minimal-claude-workspaces.git
cd minimal-claude-workspaces

# Run integrated setup (creates 2 instances with Podman)
.\scripts\powershell\Integrated-Setup.ps1 -InstanceCount 2 -SetupPodman

# Or manual setup
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command create-base
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command create -InstanceName dev1
.\scripts\powershell\WSL-Podman-Manager.ps1 -Command setup -InstanceName dev1
```

## 📁 Project Structure

```
minimal-claude-workspaces/
├── scripts/
│   ├── powershell/              # Windows management scripts
│   │   ├── WSL-MultiInstance-Manager.ps1
│   │   ├── WSL-Podman-Manager.ps1
│   │   ├── Create-MinimalWSLBase.ps1
│   │   ├── WSL-Diagnostics.ps1
│   │   └── Integrated-Setup.ps1
│   └── bash/                    # WSL instance scripts
│       ├── minimal-base-setup.sh
│       ├── setup-podman-instance.sh
│       ├── podman-workspace-manager.sh
│       ├── check-minimal-status.sh
│       └── validate-podman.sh
├── docs/
│   ├── architecture.md          # System architecture details
│   ├── setup-guide.md          # Detailed setup instructions
│   ├── troubleshooting.md      # Common issues and solutions
│   └── minimal-config.md       # Minimal configuration details
├── examples/
│   ├── docker-compose.yml      # Example compose file
│   └── sample-projects/        # Sample project templates
└── tools/
    └── quick-start.bat         # Quick start batch files
```

## 📊 Architecture Overview

```
Windows Host
├── WSL Instance 1 (claude-1)
│   ├── Minimal Ubuntu 22.04 (~500MB)
│   ├── Claude Code
│   ├── Podman (Rootless)
│   │   ├── Network: 10.101.0.0/16
│   │   └── Containers
│   └── Cloudflare Tunnel (Optional)
├── WSL Instance 2 (claude-2)
│   ├── Minimal Ubuntu 22.04 (~500MB)
│   ├── Claude Code
│   ├── Podman (Rootless)
│   │   ├── Network: 10.102.0.0/16
│   │   └── Containers
│   └── Cloudflare Tunnel (Optional)
└── PowerShell Management Scripts
```

## 📝 Instance Management

### Create a new instance
```powershell
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command create -InstanceName myproject
```

### Start/Stop instances
```powershell
# Start
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command start -InstanceName myproject

# Stop
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command stop -InstanceName myproject
```

### List all instances
```powershell
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command list
```

### Connect to an instance
```powershell
.\scripts\powershell\WSL-MultiInstance-Manager.ps1 -Command connect -InstanceName myproject
```

## 🐳 Podman Usage

### Access Podman management menu
```powershell
.\scripts\powershell\WSL-Podman-Manager.ps1 -Command menu
```

### Inside an instance
```bash
# Create a new project
podman-workspace-manager.sh create-project myapp

# Navigate to project
cd ~/projects/myapp

# Start containers
podman-compose up -d

# Check status
podman-compose ps
```

## 🔍 Minimal Configuration Details

Our minimal Ubuntu base reduces:

| Component | Standard Ubuntu | Minimal Config | Reduction |
|-----------|----------------|----------------|-----------|
| Packages | 600-800 | ~250 | ~70% |
| Disk Usage | 1.5-2.0 GB | 500-800 MB | ~65% |
| Memory (idle) | 300-400 MB | 100-150 MB | ~65% |
| Running Services | 30-40 | 10-15 | ~70% |

### Removed Components
- Snap packages and snapd
- Cloud-init
- Network Manager
- Unattended upgrades
- Most documentation and man pages
- Non-English locales
- Package recommendations

### Retained Components
- systemd (required for WSL2)
- Basic networking tools
- Git, curl, wget
- sudo
- Minimal Python3

## 🎯 Use Cases

- **Multi-tenant Development**: Isolated environments for different clients/projects
  - Client A: E-commerce site with PostgreSQL + Redis
  - Client B: API server with MongoDB + RabbitMQ
  - Personal: Experimental projects with various tech stacks
- **CI/CD Testing**: Local testing of containerized applications before deployment
- **Education**: Teaching environments where each student gets an isolated workspace
- **Microservices Development**: Test complex architectures with multiple services locally
- **Team Development**: Each developer gets their own instance with consistent configuration
- **Technology Evaluation**: Test new frameworks/tools without affecting main environment

## 🛠️ Advanced Configuration

### Resource Limits
```powershell
# Set WSL limits in .wslconfig
[wsl2]
memory=4GB
processors=2
swap=2GB

# Set Podman limits per instance
systemctl --user set-property podman.slice MemoryMax=2G
```

### Network Configuration
Each instance gets its own network range:
- Instance 1: 10.101.0.0/16
- Instance 2: 10.102.0.0/16
- Instance N: 10.10N.0.0/16

## 🐛 Troubleshooting

### Common Issues

**WSL instance won't start**
```powershell
# Check status
wsl --list --verbose

# Force terminate and restart
wsl --terminate Ubuntu-ClaudeCode-dev1
```

**Podman not working**
```bash
# Reset Podman
podman system reset

# Check user namespaces
podman unshare cat /proc/self/uid_map
```

**Disk space issues**
```powershell
# Compact VHDX
wsl --shutdown
Optimize-VHD -Path "C:\WSL\Instances\dev1\ext4.vhdx" -Mode Full
```

See [docs/troubleshooting.md](docs/troubleshooting.md) for more solutions.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- WSL2 team at Microsoft for making this possible
- Podman team at Red Hat for the excellent container runtime
- Claude AI by Anthropic for development assistance
- The open-source community for inspiration and tools

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/minimal-claude-workspaces/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/minimal-claude-workspaces/discussions)
- **Wiki**: [Project Wiki](https://github.com/YOUR_USERNAME/minimal-claude-workspaces/wiki)

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=YOUR_USERNAME/minimal-claude-workspaces&type=Date)](https://star-history.com/#YOUR_USERNAME/minimal-claude-workspaces&Date)

---

<p align="center">Made with ❤️ for the WSL and Claude Code community</p>