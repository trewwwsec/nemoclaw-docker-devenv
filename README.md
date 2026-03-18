# 🐾 NemoClaw Docker Dev Environment

**A containerized, GPU-accelerated dev environment for [NVIDIA NemoClaw](https://github.com/NVIDIA/NemoClaw) — running on macOS or Linux with ARM64/aarch64.**

NemoClaw is NVIDIA's open-source stack for running [OpenClaw](https://openclaw.ai) AI agents safely inside a sandboxed environment. It orchestrates the **OpenShell runtime**, routes inference through **NVIDIA cloud** (or local Ollama), and enforces network + filesystem security policies.

This repo provides a ready-to-use Docker image so you can run the full NemoClaw stack without touching your host system.

> ⚠️ **Alpha Software** — NemoClaw is early-stage. Interfaces and APIs may change. See the [official repo](https://github.com/NVIDIA/NemoClaw) for known limitations.

---

## ✨ What's Inside

| Layer | Component | Role |
|-------|-----------|------|
| **Base** | `nvidia/cuda:12.6.3-base-ubuntu24.04` | CUDA runtime + ARM64 |
| **Runtime** | Node.js 22 | Required by NemoClaw & OpenClaw |
| **Gateway** | NVIDIA OpenShell | Secure sandbox runtime & agent gateway |
| **Orchestrator** | **NemoClaw CLI** | Sets up sandboxes, policies, inference routing |
| **Agent** | OpenClaw (latest) | The AI agent (TUI + CLI) |
| **Sidecar** | Docker CLI (socket) | Lets the agent manage sibling containers |

---

## 🚀 Quick Start

### Prerequisites

- **Docker** installed and running
- **NVIDIA GPU** + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- **NVIDIA API Key** from [build.nvidia.com](https://build.nvidia.com) (for cloud inference)

### 1. Build the image

```bash
docker build -t nemoclaw-dev .
```

### 2. Run the container

```bash
NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx ./run-nemoclaw-ci.sh
```

Or manually:

```bash
docker run -it --rm \
  -e NVIDIA_API_KEY=nvapi-xxxxxxxxxxxx \
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
🐾 NemoClaw:  x.x.x
🤖 OpenClaw:  x.x.x
🔌 OpenShell: x.x.x
```

### 3. Chat with the agent

```bash
# Connect to a sandbox
nemoclaw my-assistant connect

# Open the interactive TUI
openclaw tui

# Or use the CLI directly
openclaw agent --agent main --local -m "hello" --session-id test
```

---

## ⚙️ Non-Interactive Onboarding

When `NVIDIA_API_KEY` is set, the container automatically runs:

```bash
NEMOCLAW_NON_INTERACTIVE=1 nemoclaw onboard --non-interactive
```

This skips the interactive wizard and configures the sandbox with your API key. If you omit the key, you'll be prompted to run `nemoclaw onboard` manually inside the container.

---

## 📁 Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `~/.nemoclaw` | `/root/.nemoclaw` | NemoClaw sandbox state & config |
| `~/.openclaw` | `/root/.openclaw` | OpenClaw agent configuration |
| `~/.openshell` | `/root/.openshell` | OpenShell gateway settings |
| `~/Documents/NemoClaw` | `/opt/NemoClaw` | Your project workspace |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (sibling containers) |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                  NemoClaw Container                   │
│                                                      │
│  ┌─────────────┐   orchestrates   ┌───────────────┐  │
│  │  NemoClaw   │◄────────────────►│  OpenShell    │  │
│  │    CLI      │                  │  Gateway :8080│  │
│  └─────────────┘                  └───────┬───────┘  │
│         │                                 │          │
│         │ manages                    sandboxes       │
│         ▼                                 │          │
│  ┌─────────────┐                  ┌───────▼───────┐  │
│  │  OpenClaw   │◄────────────────►│  Sandbox      │  │
│  │  Agent      │  TUI / CLI       │  (seccomp +   │  │
│  └─────────────┘                  │   netns)      │  │
│                                   └───────────────┘  │
│                    inference ▼                        │
│              NVIDIA Cloud / Ollama (local)            │
│                                                      │
│  Docker Socket ──────────────────► Host Docker       │
└──────────────────────────────────────────────────────┘
```

**Inference routing:**
- **Cloud** → `nvidia/nemotron-3-super-120b-a12b` via `build.nvidia.com` (requires `NVIDIA_API_KEY`)
- **Local** → Ollama with `nemotron-3-super:120b` or `nemotron-3-nano:30b` (auto-selected by VRAM)

---

## 🔑 Key Commands

### Host (NemoClaw) commands

| Command | Description |
|---------|-------------|
| `nemoclaw onboard` | Interactive setup wizard |
| `nemoclaw deploy <instance>` | Deploy a sandbox |
| `nemoclaw <name> connect` | Connect to a running sandbox |
| `nemoclaw <name> status` | Check sandbox health |
| `nemoclaw <name> logs -f` | Tail sandbox logs |
| `nemoclaw start / stop` | Start / stop sandbox |

### Inside the sandbox (OpenClaw) commands

| Command | Description |
|---------|-------------|
| `openclaw tui` | Interactive chat TUI |
| `openclaw agent --agent main --local -m "<prompt>"` | Single CLI prompt |
| `openclaw nemoclaw status` | Plugin status |
| `openclaw nemoclaw logs -f` | Plugin logs |

---

## 📋 Requirements

| Requirement | Minimum |
|-------------|---------|
| Docker | 24+ |
| NVIDIA Driver | 535+ |
| NVIDIA Container Toolkit | 1.14+ |
| RAM | 8 GB+ (16 GB recommended) |
| Architecture | `aarch64` (ARM64) |
| NVIDIA API Key | [build.nvidia.com](https://build.nvidia.com) |

> **Note:** The image targets **ARM64** (`aarch64`) via the OpenShell pip wheel. For `x86_64`, update the `jq` filter in the Dockerfile to select the appropriate wheel asset.

---

## 🛠️ Development

Your workspace (`~/Documents/NemoClaw` on host → `/opt/NemoClaw` in container) is live-mounted. Edit files on the host, they're immediately available inside the container.

```bash
# Verify the full toolchain inside the container
nemoclaw --version
openclaw --version
openshell --version
node --version
nvidia-smi
```

---

## 🔗 Links

- [NVIDIA/NemoClaw](https://github.com/NVIDIA/NemoClaw) — Official repo
- [NVIDIA/OpenShell](https://github.com/NVIDIA/OpenShell) — Sandbox runtime
- [OpenClaw](https://openclaw.ai) — AI agent framework
- [NVIDIA Agent Toolkit docs](https://docs.nvidia.com/nemo/agent-toolkit/latest)
- [NemoClaw CLI reference](https://docs.nvidia.com/nemoclaw/latest/reference/commands.md)
- [build.nvidia.com](https://build.nvidia.com) — NVIDIA API keys & model catalog

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push the branch (`git push origin feat/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is provided as-is. See [LICENSE](LICENSE) for details.
NemoClaw and OpenShell are subject to [NVIDIA's license terms](https://github.com/NVIDIA/NemoClaw/blob/main/LICENSE).
