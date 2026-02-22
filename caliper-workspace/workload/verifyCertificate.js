'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for verifying certificates (ReadAsset).
 * Reads assets that were created during InitLedger (asset1-asset6).
 */
class VerifyCertificateWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.txIndex = 0;
        // These assets are created by InitLedger in the chaincode
        this.existingAssets = ['asset1', 'asset2', 'asset3', 'asset4', 'asset5', 'asset6'];
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
    }

    async submitTransaction() {
        this.txIndex++;
        // Cycle through the known existing assets
        const assetID = this.existingAssets[this.txIndex % this.existingAssets.length];

        const request = {
            contractId: 'basic',
            contractFunction: 'ReadAsset',
            contractArguments: [assetID],
            readOnly: true
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new VerifyCertificateWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
