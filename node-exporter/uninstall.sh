#!/usr/bin/env bash
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Check if any arguments are provided
if [[ "$#" -gt 0 ]]; then
  echo "This script does not accept any arguments."
  echo "Usage: ./${0}"
  exit 1
fi

echo "Uninstalling Node Exporter..."

# Stop and disable the Node Exporter systemd service
if systemctl is-active --quiet node_exporter; then
  echo "Stopping Node Exporter service..."
  sudo systemctl stop node_exporter
fi

if systemctl is-enabled --quiet node_exporter; then
  echo "Disabling Node Exporter service..."
  sudo systemctl disable node_exporter
fi

# Remove the systemd service file
if [[ -f /etc/systemd/system/node_exporter.service ]]; then
  echo "Removing Node Exporter service file..."
  sudo rm /etc/systemd/system/node_exporter.service
  sudo systemctl daemon-reload
  sudo systemctl reset-failed
else
  echo "Node Exporter service file not found, skipping..."
fi

# Remove the Node Exporter binary
if [[ -f /usr/local/bin/node_exporter ]]; then
  echo "Removing Node Exporter binary..."
  sudo rm /usr/local/bin/node_exporter
else
  echo "Node Exporter binary not found, skipping..."
fi

# Remove the node_exporter user if it exists
if id node_exporter >/dev/null 2>&1; then
  echo "Removing node_exporter user..."
  sudo userdel -r node_exporter 2>/dev/null || true
else
  echo "node_exporter user not found, skipping..."
fi

# Clean up any leftover files in /tmp from the installation
if ls /tmp/node_exporter-* >/dev/null 2>&1; then
  echo "Cleaning up temporary files in /tmp..."
  sudo rm -rf /tmp/node_exporter-*
else
  echo "No temporary files found in /tmp, skipping..."
fi

echo "Node Exporter uninstallation completed successfully."
