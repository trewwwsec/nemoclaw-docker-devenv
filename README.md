# 🐾 NemoClaw

**GPU-accelerated dev environment for agentic AI — powered by NVIDIA OpenShell & OpenClaw.**

NemoClaw is a ready-to-run Docker container that bundles everything you need to build, test, and iterate with AI agents on NVIDIA hardware. It wires together **CUDA 12.6**, **OpenShell**, and **OpenClaw** into a single reproducible workspace so you can focus on the agent, not the setup.

---

## ✨ What's Inside

| Layer | Component | Purpose |
|-------|-----------|---------|
| **Base** | `nvidia/cuda:12.6.3-base-ubuntu24.04` | CUDA runtime + ARM64 support |
| **Runtime** | Node.js 22, Python 3 | Agent & tooling runtimes |
| **Gateway** | NVIDIA OpenShell | Local gateway for agent ↔ tool communication |
| **Agent** | OpenClaw (latest) | The AI agent framework |
| **Infra** | Docker CLI (DinD socket) | Lets the agent manage sibling containers |

---

## 🚀 Quick Start

### Prerequisites

- **Docker** installed and running
- **NVIDIA GPU** with [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (for GPU pass-through)

### 1. Build the image

```bash
docker build -t nemoclaw-dev .
```

### 2. Run the container

```bash
./run-nemoclaw-ci.sh
```

Or run manually:

```bash
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.nemoclaw:/root/.nemoclaw \
  -v ~/.openclaw:/root/.openclaw \
  -v ~/.openshell:/root/.openshell \
  -v ~/Documents/NemoClaw:/opt/NemoClaw \
  --name nemoclaw-cont \
  nemoclaw-dev
```

On startup you'll see:

```
✅ NemoClaw Dev Environment Ready
🤖 OpenClaw Agent Version: x.x.x
```

---

## 📁 Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `~/.nemoclaw` | `/root/.nemoclaw` | NemoClaw config & state |
| `~/.openclaw` | `/root/.openclaw` | OpenClaw agent configuration |
| `~/.openshell` | `/root/.openshell` | OpenShell gateway settings |
| `~/Documents/NemoClaw` | `/opt/NemoClaw` | Your project workspace |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (sibling containers) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│          NemoClaw Container             │
│                                         │
│  ┌───────────┐      ┌───────────────┐   │
│  │ OpenClaw  │◄────►│  OpenShell    │   │
│  │  Agent    │      │  Gateway      │   │
│  └───────────┘      │  :8080        │   │
│                     └──────┬────────┘   │
│                            │            │
│  ┌─────────────────────────▼──────────┐ │
│  │     CUDA 12.6 / Ubuntu 24.04      │ │
│  └────────────────────────────────────┘ │
│                     │                   │
│           Docker Socket Mount           │
└─────────────────────┼───────────────────┘
                      │
              ┌───────▼───────┐
              │  Host Docker  │
              │    Daemon     │
              └───────────────┘
```

---

## ⚙️ Configuration

Place your configuration files in the corresponding host directories before launching: 

| File | Location | Docs |
|------|----------|------|
| OpenClaw config | `~/.openclaw/` | [OpenClaw docs](https://github.com/NVIDIA/OpenClaw) |
| OpenShell config | `~/.openshell/` | [OpenShell docs](https://github.com/NVIDIA/OpenShell) |
| NemoClaw state | `~/.nemoclaw/` | — |

---

## 🛠️ Development

The container's working directory is `/opt/NemoClaw`, mapped to `~/Documents/NemoClaw` on the host. Edit files on your host and they'll be immediately available inside the container.

```bash
# Inside the container — verify the toolchain
openclaw --version
openshell --version
node --version
python3 --version
nvidia-smi          # confirm GPU access
```

---

## 📋 Requirements

| Requirement | Minimum |
|-------------|---------|
| Docker | 24+ |
| NVIDIA Driver | 535+ |
| NVIDIA Container Toolkit | 1.14+ |
| Architecture | `aarch64` (ARM64) |

> **Note:** The Dockerfile currently targets **ARM64** (`aarch64`) via the OpenShell wheel. For x86_64 builds, update the wheel selection logic on line 20 of the Dockerfile.

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feat/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is provided as-is. See [LICENSE](LICENSE) for details.
