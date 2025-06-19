#!/usr/bin/env bash
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Check if user passed Node Exporter version
if [[ "$#" -gt 1  ]]; then
    echo "This scrips requires at most ONE argument."
    echo "Usage: ./${0} [NODE_EXPORTER_VERSION]"
    exit 1
fi

# Set Node Exporter version
export VERSION=${1:-'1.9.1'} 

# Gather basic system information
export OS="$(uname | tr A-Z a-z)" # Operational System
export ARCH="$(uname -m)" # CPU Architecture

if [[ $ARCH == "x86_64" ]]; then
    export ARCH="amd64"
fi

# Download and install Node Exporter Binary
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz
tar xvfz node_exporter-*.*-${ARCH}.tar.gz
cd node_exporter-*.*-${ARCH}
sudo mv node_exporter /usr/local/bin

# Create node_exporter user with /sbin/nologin shell and no special privileges
sudo useradd -r -s /sbin/nologin -M node_exporter

# Create systemd service
sudo cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start systemd service
sudo systemctl enable --now node_exporter