#!/bin/bash
# Script to setup Zookeeper and start Kafka on EC2 instances
# Usage: Run this script on each Kafka broker

set -e

echo "=========================================="
echo "Kafka Setup Script"
echo "=========================================="
echo ""

# Install Zookeeper (if not already installed)
if [ ! -d "/opt/kafka/zookeeper" ]; then
    echo "Installing Zookeeper..."
    cd /opt/kafka
    wget -q https://archive.apache.org/dist/zookeeper/zookeeper-3.9.2/apache-zookeeper-3.9.2-bin.tar.gz
    tar -xzf apache-zookeeper-3.9.2-bin.tar.gz
    mv apache-zookeeper-3.9.2-bin zookeeper
    rm apache-zookeeper-3.9.2-bin.tar.gz
    echo "✅ Zookeeper installed"
fi

# Get private IP
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Private IP: $PRIVATE_IP"

# Configure Zookeeper
echo "Configuring Zookeeper..."
mkdir -p /data/zookeeper
echo "1" > /data/zookeeper/myid

cat > /opt/kafka/zookeeper/conf/zoo.cfg <<EOF
tickTime=2000
dataDir=/data/zookeeper
clientPort=2181
initLimit=5
syncLimit=2
server.1=$PRIVATE_IP:2888:3888
EOF

# Start Zookeeper
echo "Starting Zookeeper..."
cd /opt/kafka/zookeeper
sudo -u ec2-user bin/zkServer.sh start
sleep 5

# Check Zookeeper status
if sudo -u ec2-user bin/zkServer.sh status | grep -q "Mode: standalone"; then
    echo "✅ Zookeeper started successfully"
else
    echo "⚠️ Zookeeper may not be running properly"
fi

# Update Kafka config
echo "Updating Kafka configuration..."
sed -i "s|zookeeper.connect=localhost:2181|zookeeper.connect=$PRIVATE_IP:2181|" /opt/kafka/config/server.properties

# Start Kafka
echo "Starting Kafka..."
sudo systemctl daemon-reload
sudo systemctl enable kafka
sudo systemctl start kafka
sleep 10

# Check Kafka status
if sudo systemctl is-active --quiet kafka; then
    echo "✅ Kafka started successfully"
    sudo netstat -tlnp | grep 9092 || echo "⚠️ Port 9092 may not be listening yet"
else
    echo "❌ Kafka failed to start"
    sudo journalctl -u kafka -n 20 --no-pager
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="

