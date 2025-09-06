#!/bin/bash
set -e

echo "[+] 检测系统架构..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
  COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-aarch64"
else
  echo "[-] 不支持的架构: $ARCH"
  exit 1
fi

echo "[+] 更新系统并安装依赖..."
apt update -y
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "[+] 添加 Docker GPG 密钥和源..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[+] 安装 Docker 引擎..."
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[+] 安装 Docker Compose v2..."
curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "[+] 启动 Docker 服务..."
systemctl enable docker
systemctl start docker

echo "[+] 部署 Portainer Agent 容器..."
docker run -d \
  --name portainer_agent \
  --restart=always \
  -p 9001:9001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  -e AGENT_SECRET=aB7kP2xQ9LmT8vYcR3nWzE6HdJfU1gAo \
  portainer/agent:2.27.6

echo "[✓] 安装完成！Portainer Agent 已运行在 9001 端口。"
