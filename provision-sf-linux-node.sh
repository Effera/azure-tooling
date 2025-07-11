#!/bin/bash

set -e

# 🌟 Input: SF runtime version (e.g. U22.11.0.2707.4)
SF_RUNTIME_VERSION="$1"

if [ -z "$SF_RUNTIME_VERSION" ]; then
  echo "❌ Missing Service Fabric runtime version. Usage: $0 U22.11.0.2707.4"
  exit 1
fi

echo "servicefabric servicefabric/accepted-eula boolean true" | sudo debconf-set-selections
echo "servicefabric servicefabric/accepted-all-eula boolean true" | sudo debconf-set-selections

# 🔗 Construct runtime download URL
BASE_URL="https://download.microsoft.com/download/3/1/F/31F3FEEB-F073-4E27-A98B-8E691FF74F40"
RUNTIME_FILE="ServiceFabric.$SF_RUNTIME_VERSION.deb"
DOWNLOAD_URL="$BASE_URL/$RUNTIME_FILE"
TARGET_DIR="/var/lib/waagent/Microsoft.Azure.ServiceFabric.ServiceFabricLinuxNode-2.0.0.0/Service"
TARGET_PATH="$TARGET_DIR/ServiceFabricRuntime.deb"

echo "📦 Installing core dependencies and Docker..."
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  cgroup-tools \
  aspnetcore-runtime-8.0 \
  ebtables \
  lttng-tools \
  liblttng-ust1 \
  nodejs \
  libssh2-1

# 🛡️ Setup Docker repository and install engine
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

echo "📁 Creating target folder for SF runtime..."
mkdir -p "$TARGET_DIR"

echo "🌐 Downloading Service Fabric runtime: $DOWNLOAD_URL"
wget "$DOWNLOAD_URL" -O "$TARGET_PATH"

echo "🛠️ Installing Service Fabric runtime..."
sudo dpkg -i "$TARGET_PATH"

echo "🔁 Enabling and starting Service Fabric service..."
sudo systemctl enable servicefabric
sudo systemctl start servicefabric

echo "✅ Node provisioning complete with Service Fabric runtime $SF_RUNTIME_VERSION."