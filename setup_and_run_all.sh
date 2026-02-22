#!/bin/bash
set -e

# ==============================================================
# Blockchain Certificate Management System (BCMS)
# Full Automated Setup & Run Script
# Compatible with: GitHub Codespaces / Local Linux / WSL2 / macOS
# ==============================================================

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Auto-detect ROOT_DIR (works in Codespaces and locally)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH=${ROOT_DIR}/bin:$PATH
export FABRIC_CFG_PATH=${ROOT_DIR}/config/

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}   Blockchain Certificate Management System (BCMS)${NC}"
echo -e "${BLUE}   Full Automated Setup & Run${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""
echo -e "${GREEN}ROOT_DIR: ${ROOT_DIR}${NC}"

# ============================================================
# STEP 1: Check and Install Prerequisites
# ============================================================
echo ""
echo -e "${GREEN}=== Step 1/6: Checking Prerequisites ===${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi
echo -e "${GREEN}  Docker: OK${NC}"

# Check Docker Compose
if docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}  Docker Compose: OK${NC}"
elif docker-compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}  Docker Compose (legacy): OK${NC}"
else
    echo -e "${RED}ERROR: Docker Compose not found.${NC}"
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}  Node.js not found. Installing via nvm...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
fi
echo -e "${GREEN}  Node.js: $(node --version)${NC}"
echo -e "${GREEN}  npm: $(npm --version)${NC}"

# Check Go
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}  Go not found. Installing Go 1.22...${NC}"
    wget -q https://go.dev/dl/go1.22.5.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
fi
echo -e "${GREEN}  Go: $(go version 2>/dev/null || echo 'will be installed')${NC}"

# ============================================================
# STEP 2: Download Fabric Binaries & Docker Images
# ============================================================
echo ""
echo -e "${GREEN}=== Step 2/6: Checking Fabric Binaries ===${NC}"

cd "$ROOT_DIR"

if [ ! -d "bin" ] || [ ! -f "bin/peer" ]; then
    echo -e "${YELLOW}  Downloading Fabric binaries and Docker images...${NC}"
    echo -e "${YELLOW}  This may take a few minutes on first run...${NC}"
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.9 1.5.7
    echo -e "${GREEN}  Fabric binaries downloaded successfully.${NC}"
else
    echo -e "${GREEN}  Fabric binaries already present.${NC}"
fi

# Verify peer binary works
if ! ${ROOT_DIR}/bin/peer version &> /dev/null; then
    echo -e "${RED}ERROR: Fabric peer binary is not working.${NC}"
    exit 1
fi
echo -e "${GREEN}  Fabric peer version: $(${ROOT_DIR}/bin/peer version 2>&1 | grep 'Version:' | head -1)${NC}"

# ============================================================
# STEP 3: Start Fabric Network
# ============================================================
echo ""
echo -e "${GREEN}=== Step 3/6: Starting Fabric Network ===${NC}"

cd "$ROOT_DIR/test-network"

# Clean up any previous network
echo -e "${YELLOW}  Cleaning up previous network...${NC}"
./network.sh down 2>/dev/null || true

# Start the network with CA and create channel
echo -e "${YELLOW}  Starting network with CA and creating channel 'mychannel'...${NC}"
./network.sh up createChannel -c mychannel -ca

echo -e "${GREEN}  Network started successfully!${NC}"

# ============================================================
# STEP 4: Deploy Smart Contract (Chaincode Go)
# ============================================================
echo ""
echo -e "${GREEN}=== Step 4/6: Deploying Smart Contract (Go Chaincode) ===${NC}"

echo -e "${YELLOW}  Deploying 'basic' chaincode from asset-transfer-basic/chaincode-go...${NC}"
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

echo -e "${GREEN}  Smart contract deployed successfully!${NC}"

# Initialize the ledger with sample data
echo -e "${YELLOW}  Initializing ledger with sample data...${NC}"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

${ROOT_DIR}/bin/peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "${ROOT_DIR}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
    -C mychannel \
    -n basic \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${ROOT_DIR}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    -c '{"function":"InitLedger","Args":[]}' \
    --waitForEvent

echo -e "${GREEN}  Ledger initialized with 6 sample assets!${NC}"

# Verify by querying all assets
echo -e "${YELLOW}  Verifying deployment by querying all assets...${NC}"
RESULT=$(${ROOT_DIR}/bin/peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}' 2>&1)
echo -e "${GREEN}  Query result: ${RESULT}${NC}"

# ============================================================
# STEP 5: Configure and Run Caliper Benchmarks
# ============================================================
echo ""
echo -e "${GREEN}=== Step 5/6: Configuring & Running Caliper Benchmarks ===${NC}"

cd "$ROOT_DIR/caliper-workspace"

# Find private key dynamically
echo -e "${YELLOW}  Locating private key...${NC}"
KEY_DIR="${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore"
KEY_FILE=$(find "$KEY_DIR" -name "*_sk" -type f | head -n 1)

if [ -z "$KEY_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}ERROR: Private key not found at $KEY_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}  Private Key: $KEY_FILE${NC}"

# Find cert file
CERT_FILE="${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts"
if [ -f "$CERT_FILE/User1@org1.example.com-cert.pem" ]; then
    CERT_FILE="$CERT_FILE/User1@org1.example.com-cert.pem"
elif [ -f "$CERT_FILE/cert.pem" ]; then
    CERT_FILE="$CERT_FILE/cert.pem"
else
    echo -e "${RED}ERROR: Certificate not found${NC}"
    exit 1
fi
echo -e "${GREEN}  Certificate: $CERT_FILE${NC}"

# Create networks directory
mkdir -p networks

# Generate networkConfig.yaml with correct dynamic paths and discover: false
cat > networks/networkConfig.yaml << NETEOF
name: Fabric Certificate Benchmark
version: "2.0.0"

caliper:
  blockchain: fabric

channels:
  - channelName: mychannel
    contracts:
      - id: basic

organizations:
  - mspid: Org1MSP
    identities:
      certificates:
        - name: 'User1'
          clientPrivateKey:
            path: '${KEY_FILE}'
          clientSignedCert:
            path: '${CERT_FILE}'
    connectionProfile:
      path: 'networks/connection-org1.yaml'
      discover: false
NETEOF

echo -e "${GREEN}  networkConfig.yaml created (discover: false)${NC}"

# Generate connection-org1.yaml with full peer/orderer mapping
cat > networks/connection-org1.yaml << CONNEOF
name: test-network-org1
version: 1.0.0
client:
  organization: Org1
  connection:
    timeout:
      peer:
        endorser: '300'
      orderer: '300'

channels:
  mychannel:
    orderers:
      - orderer.example.com
    peers:
      peer0.org1.example.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true
      peer0.org2.example.com:
        endorsingPeer: true
        chaincodeQuery: true
        ledgerQuery: true
        eventSource: true

organizations:
  Org1:
    mspid: Org1MSP
    peers:
      - peer0.org1.example.com
    certificateAuthorities:
      - ca.org1.example.com

  Org2:
    mspid: Org2MSP
    peers:
      - peer0.org2.example.com

orderers:
  orderer.example.com:
    url: grpcs://localhost:7050
    grpcOptions:
      ssl-target-name-override: orderer.example.com
      hostnameOverride: orderer.example.com
    tlsCACerts:
      path: ${ROOT_DIR}/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peers:
  peer0.org1.example.com:
    url: grpcs://localhost:7051
    grpcOptions:
      ssl-target-name-override: peer0.org1.example.com
      hostnameOverride: peer0.org1.example.com
    tlsCACerts:
      path: ${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

  peer0.org2.example.com:
    url: grpcs://localhost:9051
    grpcOptions:
      ssl-target-name-override: peer0.org2.example.com
      hostnameOverride: peer0.org2.example.com
    tlsCACerts:
      path: ${ROOT_DIR}/test-network/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

certificateAuthorities:
  ca.org1.example.com:
    url: https://localhost:7054
    caName: ca-org1
    tlsCACerts:
      path: ${ROOT_DIR}/test-network/organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem
    httpOptions:
      verify: false
CONNEOF

echo -e "${GREEN}  connection-org1.yaml created with full peer mapping${NC}"

# Install npm dependencies
echo -e "${YELLOW}  Installing Caliper dependencies...${NC}"
npm install 2>&1 | tail -3

# Bind Caliper to Fabric 2.5
echo -e "${YELLOW}  Binding Caliper to Fabric 2.5 SDK...${NC}"
npx caliper bind --caliper-bind-sut fabric:2.5

# Run the benchmark
echo -e "${YELLOW}  Launching benchmark... (this takes ~2-3 minutes)${NC}"
npx caliper launch manager \
    --caliper-workspace ./ \
    --caliper-networkconfig networks/networkConfig.yaml \
    --caliper-benchconfig benchmarks/benchConfig.yaml \
    --caliper-flow-only-test \
    --caliper-fabric-gateway-enabled

# ============================================================
# STEP 6: Results Summary
# ============================================================
echo ""
echo -e "${BLUE}=================================================================${NC}"
echo -e "${GREEN}   ALL DONE! Project Setup & Benchmark Complete!${NC}"
echo -e "${BLUE}=================================================================${NC}"
echo ""
echo -e "${GREEN}  Network Status:       RUNNING${NC}"
echo -e "${GREEN}  Smart Contract:       Deployed (basic - Go)${NC}"
echo -e "${GREEN}  Channel:              mychannel${NC}"
echo -e "${GREEN}  Benchmark Report:     caliper-workspace/report.html${NC}"
echo ""
echo -e "${YELLOW}  To view the report, open: caliper-workspace/report.html${NC}"
echo -e "${YELLOW}  To stop the network:  cd test-network && ./network.sh down${NC}"
echo ""
echo -e "${BLUE}=================================================================${NC}"
