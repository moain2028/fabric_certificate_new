#!/bin/bash
set -e

echo "================================================================="
echo "  Quick Network Setup Script"
echo "  Starts Fabric network + deploys chaincode"
echo "================================================================="

# Auto-detect ROOT_DIR
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH=${ROOT_DIR}/bin:$PATH
export FABRIC_CFG_PATH=${ROOT_DIR}/config/

# 1. Download Fabric binaries if not present
if [ ! -d "${ROOT_DIR}/bin" ] || [ ! -f "${ROOT_DIR}/bin/peer" ]; then
    echo "Downloading Fabric binaries..."
    cd "$ROOT_DIR"
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.9 1.5.7
else
    echo "Fabric binaries already present."
fi

# 2. Fix permissions
echo "Fixing permissions..."
chmod -R +x "${ROOT_DIR}/test-network/"
chmod +x "${ROOT_DIR}/setup_and_run_all.sh"

# 3. Start network
cd "${ROOT_DIR}/test-network" || { echo "ERROR: test-network directory not found!"; exit 1; }

echo "Cleaning up previous network..."
./network.sh down 2>/dev/null || true

echo "Starting network with CA and creating channel..."
./network.sh up createChannel -c mychannel -ca

# 4. Deploy chaincode
echo "Deploying Go chaincode..."
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

echo ""
echo "================================================================="
echo "  Network is UP! Chaincode deployed."
echo "  Channel: mychannel | Chaincode: basic (Go)"
echo "================================================================="
echo ""
echo "Next steps:"
echo "  - Run Caliper:  cd caliper-workspace && ./fix_and_run_caliper.sh"
echo "  - Or full test:  cd .. && ./setup_and_run_all.sh"
