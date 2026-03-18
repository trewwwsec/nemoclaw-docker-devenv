# 1. Base Image (Ubuntu 24.04 for glibc 2.39 + ARM64 support)
FROM nvidia/cuda:12.6.3-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# 2. System Dependencies
RUN apt-get update && apt-get install -y \
    curl git sudo python3 python3-pip python3-venv jq ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# 3. Docker CLI (Inside-to-Outside communication)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli

# 4. Node.js 22 & OpenShell (manylinux_2_39_aarch64)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && apt-get install -y nodejs
RUN WHEEL_URL=$(curl -s https://api.github.com/repos/NVIDIA/OpenShell/releases/latest | jq -r '.assets[] | select(.name | contains("aarch64.whl")) | .browser_download_url') && \
    pip3 install --break-system-packages "$WHEEL_URL"

# 5. Install OpenClaw (The Agent)
# Installing globally so 'openclaw' command is available immediately
RUN npm install -g openclaw@latest

# 6. Persistent Config Dirs
RUN mkdir -p /root/.nemoclaw /root/.openclaw /root/.openshell /opt/NemoClaw
WORKDIR /opt/NemoClaw

# 7. Updated Entrypoint Script
RUN echo '#!/bin/bash\n\
npm install -g . > /dev/null 2>&1\n\
openshell gateway connect --name nemoclaw --address 127.0.0.1:8080 > /dev/null 2>&1\n\
echo "✅ NemoClaw Dev Environment Ready"\n\
echo "🤖 OpenClaw Agent Version: $(openclaw --version)"\n\
exec "$@"' > /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
