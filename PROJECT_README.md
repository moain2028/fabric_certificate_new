# Blockchain Certificate Management System (BCMS)

**A Hyperledger Fabric & Go Implementation with Caliper Benchmarking**

---

## 1. Project Description

This is a decentralized, secure system for **issuing, managing, and protecting academic certificates** from forgery using **Hyperledger Fabric** technology. The system relies on a **Smart Contract** written in **Go** for high performance and verification efficiency. The project also includes comprehensive performance tests using **Hyperledger Caliper**.

---

## 2. System Architecture

| Component | Details |
| :--- | :--- |
| **Blockchain Network** | **Hyperledger Fabric v2.5** (Latest Stable) |
| **Consensus** | **Raft** (EtcdRaft) |
| **Organizations** | **2 Organizations (Org1, Org2)** + **1 Orderer** |
| **Smart Contract** | **Golang (Go)** - asset-transfer-basic |
| **Benchmarking** | **Hyperledger Caliper 0.6.0** |
| **Database** | **LevelDB** (default) |

### Smart Contract Functions

| Function | Description |
| :--- | :--- |
| `CreateAsset` | Issue a new certificate (ID, Color, Size, Owner, AppraisedValue) |
| `ReadAsset` | Verify/Read a certificate by ID |
| `GetAllAssets` | Query all certificates |
| `DeleteAsset` | Revoke/Delete a certificate |
| `UpdateAsset` | Update certificate details |
| `TransferAsset` | Transfer certificate ownership |
| `InitLedger` | Initialize with sample data |

---

## 3. Quick Start Guide

### Option A: GitHub Codespaces (Recommended - Cloud)

1. Click **"Code"** > **"Create codespace on main"** on the GitHub repo page
2. Wait for the Codespace to build (~2-3 minutes)
3. Open the Terminal and run:

```bash
chmod +x setup_and_run_all.sh
./setup_and_run_all.sh
```

**What happens:**
- Downloads Fabric binaries & Docker images (~3 min first time)
- Starts Fabric network with 2 orgs + orderer + CA
- Deploys Go smart contract
- Initializes ledger with sample data
- Runs Caliper benchmarks (4 rounds)
- Generates HTML report

**Total time: ~8-12 minutes on first run**

### Option B: Local Machine (Linux / macOS / WSL2)

**Prerequisites:**
- Docker Desktop (running)
- Go 1.19+
- Node.js 18+
- Git & cURL

```bash
# Clone
git clone https://github.com/moain2028/fabric_certificate_new.git
cd fabric_certificate_new

# Run
chmod +x setup_and_run_all.sh
./setup_and_run_all.sh
```

### Option C: Step-by-Step Manual

```bash
# Step 1: Download Fabric
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.9 1.5.7
export PATH=$PWD/bin:$PATH

# Step 2: Start network
cd test-network
./network.sh down
./network.sh up createChannel -c mychannel -ca

# Step 3: Deploy chaincode
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

# Step 4: Run Caliper
cd ../caliper-workspace
./fix_and_run_caliper.sh
```

---

## 4. Benchmark Results

After completion, the report is generated at: `caliper-workspace/report.html`

The benchmark tests 4 phases:
- **Issue Certificates**: Measures certificate creation throughput (TPS)
- **Verify Certificate**: Measures read/verification latency
- **Query All**: Measures bulk data retrieval performance
- **Revoke Certificate**: Measures deletion throughput

---

## 5. Project Structure

| Path | Description |
| :--- | :--- |
| `setup_and_run_all.sh` | Full automation script |
| `setup_network.sh` | Quick network setup only |
| `test-network/` | Fabric network configuration |
| `asset-transfer-basic/chaincode-go/` | Go smart contract |
| `caliper-workspace/` | Caliper benchmarking workspace |
| `caliper-workspace/fix_and_run_caliper.sh` | Caliper fix & run script |
| `caliper-workspace/workload/` | Benchmark workload modules |
| `caliper-workspace/benchmarks/` | Benchmark configuration |
| `caliper-workspace/report.html` | Generated performance report |
| `.devcontainer/` | Codespaces configuration |

---

## 6. Troubleshooting

### Common Issues

| Issue | Solution |
| :--- | :--- |
| Docker not running | Start Docker Desktop first |
| Permission denied | `chmod -R +x test-network/ && chmod +x *.sh` |
| Port already in use | `cd test-network && ./network.sh down` |
| Caliper fails | Run `cd caliper-workspace && ./fix_and_run_caliper.sh` |

### Clean Restart

```bash
cd test-network
./network.sh down
docker system prune -f
cd ..
./setup_and_run_all.sh
```

---

## License

This project is licensed under the **Apache-2.0 License**.
