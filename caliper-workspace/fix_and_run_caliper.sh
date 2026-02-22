#!/bin/bash
set -e

echo "================================================================="
echo "  Caliper Fix & Run Script"
echo "  Fixes common issues and runs benchmark"
echo "================================================================="

# ============================================================
# 1. Auto-detect ROOT_DIR (works in Codespaces and locally)
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -d "$ROOT_DIR/test-network" ]; then
    echo "ERROR: Cannot find test-network directory."
    echo "Expected at: $ROOT_DIR/test-network"
    echo "Make sure you're running this from caliper-workspace/"
    exit 1
fi

echo "ROOT_DIR: $ROOT_DIR"
export PATH=${ROOT_DIR}/bin:$PATH

# ============================================================
# 2. Verify network is running
# ============================================================
echo ""
echo "Checking if Fabric network is running..."

if ! docker ps | grep -q "peer0.org1.example.com"; then
    echo "WARNING: Fabric network does not appear to be running."
    echo "Starting the network..."
    cd "$ROOT_DIR/test-network"
    ./network.sh down 2>/dev/null || true
    ./network.sh up createChannel -c mychannel -ca
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go
    cd "$SCRIPT_DIR"
    echo "Network started and chaincode deployed."
else
    echo "Fabric network is running."
fi

# ============================================================
# 3. Find private key dynamically
# ============================================================
echo ""
echo "Searching for private key..."

KEY_DIR="$ROOT_DIR/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore"
KEY_FILE=$(find "$KEY_DIR" -name "*_sk" -type f 2>/dev/null | head -n 1)

if [ -z "$KEY_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Private key not found. Ensure network is running with -ca flag."
    exit 1
fi
echo "Private Key Found: $KEY_FILE"

# Find certificate
CERT_DIR="$ROOT_DIR/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts"
if [ -f "$CERT_DIR/User1@org1.example.com-cert.pem" ]; then
    CERT_FILE="$CERT_DIR/User1@org1.example.com-cert.pem"
elif [ -f "$CERT_DIR/cert.pem" ]; then
    CERT_FILE="$CERT_DIR/cert.pem"
else
    echo "ERROR: Certificate not found at $CERT_DIR"
    exit 1
fi
echo "Certificate Found: $CERT_FILE"

# ============================================================
# 4. Generate networkConfig.yaml (discover: false)
# ============================================================
echo ""
echo "Generating network config files..."

cd "$SCRIPT_DIR"
mkdir -p networks

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

echo "networkConfig.yaml created (discover: false)"

# ============================================================
# 5. Generate connection-org1.yaml
# ============================================================
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

echo "connection-org1.yaml created"

# ============================================================
# 6. Install dependencies and run Caliper
# ============================================================
echo ""
echo "Installing Caliper dependencies..."
npm install 2>&1 | tail -5

echo ""
echo "Binding Caliper to Fabric 2.5..."
npx caliper bind --caliper-bind-sut fabric:2.5

echo ""
echo "Launching Caliper Benchmark..."
npx caliper launch manager \
    --caliper-workspace ./ \
    --caliper-networkconfig networks/networkConfig.yaml \
    --caliper-benchconfig benchmarks/benchConfig.yaml \
    --caliper-flow-only-test \
    --caliper-fabric-gateway-enabled

echo ""
echo "================================================================="
echo "  Benchmark completed!"
echo "  Report: $(pwd)/report.html"
echo "================================================================="
