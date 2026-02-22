# Summary of Bugs Fixed

## Critical Bugs Found and Fixed

### Bug 1: Wrong Contract Arguments in issueCertificate.js
**Problem:** The workload was passing `(certID, 'Student Name', 95, 'Course', 2025)` but the Go smart contract `CreateAsset` expects `(id, color, size, owner, appraisedValue)` where `size` and `appraisedValue` are integers.
**Fix:** Changed arguments to match the contract signature: `(assetID, 'blue', '5', 'CertOwner', '300')`

### Bug 2: Non-existent Function in revokeCertificate.js
**Problem:** Called `RevokeCertificate` which does NOT exist in the smart contract.
**Fix:** Changed to `DeleteAsset` which is the actual function name. Also fixed ID prefix mismatch (`CERT_` vs `cert_`). Added pre-creation of assets in `initializeWorkloadModule` so deletion actually has assets to delete.

### Bug 3: Non-existent Function in queryAllCertificates.js
**Problem:** Called `QueryAllCertificatesWithPagination` which does NOT exist in the smart contract.
**Fix:** Changed to `GetAllAssets` with no arguments (the actual function signature).

### Bug 4: verifyCertificate.js Reading Non-existent Assets
**Problem:** Tried to read `cert_X_Y` assets which may not exist, causing failures.
**Fix:** Changed to read from known `InitLedger` assets (`asset1` through `asset6`).

### Bug 5: Service Discovery Enabled (discover: true)
**Problem:** `discover: true` in networkConfig causes `No endorsement plan available` errors in Codespaces/Docker environments.
**Fix:** Set `discover: false` and added full manual peer/orderer mapping in connection profile.

### Bug 6: Hardcoded ROOT_DIR Paths
**Problem:** `fix_and_run_caliper.sh` had `ROOT_DIR="/workspaces/fabric_certificate_MT"` - only works in specific Codespace.
**Fix:** Auto-detect `ROOT_DIR` dynamically using `$(cd "$(dirname "$0")" && pwd)`.

### Bug 7: Hardcoded Private Key Path
**Problem:** Certificate path was hardcoded to `priv_sk` but actual filename contains a random hash.
**Fix:** Use `find` command to dynamically locate `*_sk` files.

### Bug 8: Wrong Caliper Binding Version
**Problem:** `setup_and_run_all.sh` bound to `fabric:2.2` instead of `fabric:2.5`.
**Fix:** Changed to `npx caliper bind --caliper-bind-sut fabric:2.5`.

### Bug 9: Certificate Path Issue
**Problem:** Cert file can be `cert.pem` or `User1@org1.example.com-cert.pem` depending on CA setup.
**Fix:** Added fallback logic to check both paths.

### Bug 10: Missing .devcontainer for Codespaces
**Problem:** No `.devcontainer/devcontainer.json` file - Codespaces doesn't auto-configure Docker-in-Docker, Go, Node.js.
**Fix:** Added complete `.devcontainer/devcontainer.json` with all required features.

### Bug 11: Missing Connection Profile Peer Mapping
**Problem:** `connection-org1.yaml` template only had Org1 peer, no orderer, no Org2 peer.
**Fix:** Added complete channel/orderer/peer mapping for both organizations.

### Bug 12: Caliper Package Version Mismatch
**Problem:** `package.json` had `@hyperledger/caliper-cli: 0.5.0` and `fabric-network: ^2.2.12` (outdated).
**Fix:** Updated to `@hyperledger/caliper-cli: 0.6.0` and `@hyperledger/caliper-core: 0.6.0`.

## Verification Checklist

- [x] `discover: false` in networkConfig
- [x] Dynamic private key discovery using `find`
- [x] Correct `CreateAsset` arguments: (id, color, size, owner, appraisedValue)
- [x] Correct function names: `DeleteAsset` (not RevokeCertificate)
- [x] Correct function names: `GetAllAssets` (not QueryAllCertificatesWithPagination)
- [x] Caliper bound to `fabric:2.5`
- [x] Auto-detect ROOT_DIR (not hardcoded)
- [x] Full peer/orderer mapping in connection profile
- [x] `.devcontainer` for Codespaces support
- [x] InitLedger called after chaincode deployment
- [x] Certificate path fallback logic
