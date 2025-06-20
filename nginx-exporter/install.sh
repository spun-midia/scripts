#!/usr/bin/env bash
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Check if user passed Node Exporter version
if [[ "$#" -gt 1  ]]; then
    echo "This scrips accepts at most ONE argument."
    echo "Usage: ./${0} [NGINX_EXPORTER_VERSION]"
    exit 1
fi

# Set Node Exporter version
export VERSION=${1:-'1.4.2'} 

# Gather basic system information
export OS="$(uname | tr A-Z a-z)" # Operational System
export ARCH="$(uname -m)" # CPU Architecture

if [[ $ARCH == "x86_64" ]]; then
    export ARCH="amd64"
elif [[ $ARCH == "aarch64" ]]; then
    export ARCH="arm64"
fi

# Download and install Node Exporter Binary
cd /tmp
wget https://github.com/nginx/nginx-prometheus-exporter/releases/download/v${VERSION}/nginx-prometheus-exporter_${VERSION}_${OS}_${ARCH}.tar.gz
tar xvfz nginx-prometheus-exporter-*.*-${ARCH}.tar.gz
cd nginx-prometheus-exporter-*.*-${ARCH}
sudo mv nginx-prometheus-exporter /usr/local/bin

# Create node_exporter user with /sbin/nologin shell and no special privileges
# If it doesn't exist
if [[ ! $(id -u nginx_exporter) ]]; then
    sudo useradd -r -s /sbin/nologin -M nginx_exporter
fi

# Create systemd service
cat <<EOF > nginx_exporter.service
[Unit]
Description=Nginx Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/nginx-prometheus-exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo mv nginx_exporter.service /etc/systemd/system

# Enable and start systemd service
sudo systemctl enable --now nginx_exporter
