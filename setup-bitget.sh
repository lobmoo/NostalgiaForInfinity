#!/bin/bash
# Bitget 5x Strategy Setup Script
# Usage: ./setup-bitget.sh [proxy_address]
# Example: ./setup-bitget.sh http://127.0.0.1:9001

set -e

PROXY="${1:-http://127.0.0.1:9001}"
STRATEGY="NostalgiaForInfinityX7_5x"

echo "=========================================="
echo " Bitget 5x Strategy Setup"
echo " Proxy: $PROXY"
echo "=========================================="

# Create necessary directories
echo "[1/5] Creating directories..."
mkdir -p user_data/data user_data/logs user_data/backtest_results

# Build custom freqtrade image with numba
echo "[2/5] Building freqtrade_with_numba image..."
docker build \
  --build-arg HTTP_PROXY="$PROXY" \
  --build-arg HTTPS_PROXY="$PROXY" \
  -f docker/Dockerfile.custom \
  -t freqtrade_with_numba \
  . 2>&1 | tail -5

# Update proxy in config files
echo "[3/5] Updating proxy in config files..."
sed -i "s|http://127.0.0.1:9001|$PROXY|g" configs/config-bitget-dryrun.json
sed -i "s|http://127.0.0.1:9001|$PROXY|g" docker-compose-bitget.yml

# Prompt for API keys
echo "[4/5] Configure API keys..."
echo "Please edit configs/config-bitget-dryrun.json and fill in your Bitget API credentials:"
echo "  - key: Your API Key"
echo "  - secret: Your API Secret"
echo "  - password: Your API Passphrase"
echo ""
echo "Press Enter when done (or Ctrl+C to skip and configure later)..."
read -r

# Start services
echo "[5/5] Starting services..."
docker compose -f docker-compose-bitget.yml up -d --build

echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
echo ""
echo "Services running:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "bitget|nfi"
echo ""
echo "Useful commands:"
echo "  docker logs -f bitget-dryrun           # View trading logs"
echo "  docker logs -f nfi-updater-bitget      # View updater logs"
echo "  docker restart bitget-dryrun           # Restart bot"
echo "  docker compose -f docker-compose-bitget.yml down  # Stop all"
echo ""
