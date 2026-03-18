# =============================================================================
# NemoClaw Docker Dev Environment
# Base: NVIDIA CUDA 12.6 on Ubuntu 24.04 (ARM64 / aarch64)
# Provides: NemoClaw CLI + OpenShell gateway + OpenClaw agent
# =============================================================================

# 1. Base Image — glibc 2.39 + ARM64/CUDA support
FROM nvidia/cuda:12.6.3-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# 2. System Dependencies
RUN apt-get update && apt-get install -y \
    curl git sudo python3 python3-pip python3-venv jq ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# 3. Docker CLI (lets the agent manage sibling containers via socket)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli

# 4. Node.js 22 (required by NemoClaw and OpenClaw)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && \
    apt-get install -y nodejs

# 5. OpenShell — NVIDIA agent runtime gateway (aarch64 wheel)
RUN WHEEL_URL=$(curl -s https://api.github.com/repos/NVIDIA/OpenShell/releases/latest | jq -r '.assets[] | select(.name | contains("aarch64.whl")) | .browser_download_url') && \
    pip3 install --break-system-packages "$WHEEL_URL"

# 6. NemoClaw — NVIDIA plugin / CLI that orchestrates OpenShell + OpenClaw
#    Installed directly from the official NVIDIA GitHub repo (npm package).
#    SSH key is NOT needed here; HTTPS is used at runtime via the installer.
RUN npm install -g git+https://github.com/nvidia/NemoClaw.git

# 7. OpenClaw — The AI agent (managed by NemoClaw, also available standalone)
RUN npm install -g openclaw@latest

# 8. Persistent config & workspace directories
RUN mkdir -p /root/.nemoclaw /root/.openclaw /root/.openshell /opt/NemoClaw
WORKDIR /opt/NemoClaw

# 9. Entrypoint
#    - NON_INTERACTIVE=1  → skips the interactive onboard wizard
#    - Set NVIDIA_API_KEY in your environment or docker run command to
#      authenticate against build.nvidia.com for cloud inference.
#    - The openshell gateway is started before NemoClaw onboards.
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
# If a local package.json exists, install it (dev workflow)\n\
if [ -f /opt/NemoClaw/package.json ]; then\n\
  npm install -g . > /dev/null 2>&1\n\
fi\n\
\n\
# Start the OpenShell gateway\n\
openshell gateway connect --name nemoclaw --address 127.0.0.1:8080 > /dev/null 2>&1 &\n\
\n\
# Run nemoclaw onboard non-interactively if NVIDIA_API_KEY is set\n\
if [ -n "${NVIDIA_API_KEY:-}" ]; then\n\
  NEMOCLAW_NON_INTERACTIVE=1 nemoclaw onboard --non-interactive 2>&1 || true\n\
else\n\
  echo "⚠️  NVIDIA_API_KEY not set — skipping auto-onboard. Run: nemoclaw onboard"\n\
fi\n\
\n\
echo "✅ NemoClaw Dev Environment Ready"\n\
echo "🐾 NemoClaw:  $(nemoclaw --version 2>/dev/null || echo n/a)"\n\
echo "🤖 OpenClaw:  $(openclaw --version 2>/dev/null || echo n/a)"\n\
echo "🔌 OpenShell: $(openshell --version 2>/dev/null || echo n/a)"\n\
\n\
exec "$@"\n' > /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
