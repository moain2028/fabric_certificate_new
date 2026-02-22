'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for revoking certificates (DeleteAsset).
 * First creates an asset, then deletes it to ensure success.
 * Uses the correct function name: DeleteAsset (NOT RevokeCertificate).
 */
class RevokeCertificateWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.txIndex = 0;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;

        // Pre-create assets that will be deleted in the benchmark round
        for (let i = 1; i <= 50; i++) {
            const assetID = `del_w${this.workerIndex}_t${i}`;
            try {
                const createReq = {
                    contractId: 'basic',
                    contractFunction: 'CreateAsset',
                    contractArguments: [assetID, 'red', '10', 'ToDelete', '100'],
                    readOnly: false
                };
                await this.sutAdapter.sendRequests(createReq);
            } catch (e) {
                // Asset may already exist, ignore
            }
        }
    }

    async submitTransaction() {
        this.txIndex++;
        const assetID = `del_w${this.workerIndex}_t${this.txIndex}`;

        const request = {
            contractId: 'basic',
            contractFunction: 'DeleteAsset',
            contractArguments: [assetID],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new RevokeCertificateWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
