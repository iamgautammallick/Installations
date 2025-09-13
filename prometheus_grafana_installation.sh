#!/bin/bash
set -e

# Update system
sudo apt update && sudo apt upgrade -y

# ----------------------------
# Install Prometheus
# ----------------------------
PROM_VERSION="2.54.1" # latest stable as of Sept 2025, adjust if needed
cd /tmp
curl -LO "https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz"
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROM_VERSION}.linux-amd64 /usr/local/prometheus

# Create Prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus

# Set ownership
sudo chown -R prometheus:prometheus /usr/local/prometheus

# Create Prometheus data directory
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Systemd service for Prometheus
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/prometheus/prometheus \\
  --config.file=/usr/local/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus \\
  --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# ----------------------------
# Install Grafana
# ----------------------------
sudo apt install -y software-properties-common
sudo mkdir -p /etc/apt/keyrings/

# Add Grafana GPG key
wget -q -O - https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

# Add Grafana repo
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
sudo apt update
sudo apt install -y grafana

# Enable and start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

echo "----------------------------------------"
echo "Prometheus is running on: http://localhost:9090"
echo "Grafana is running on:    http://localhost:3000"
echo "Default Grafana login: admin / admin"
echo "----------------------------------------"
