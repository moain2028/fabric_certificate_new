'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for issuing certificates (CreateAsset).
 * Arguments must match the Go smart contract:
 *   CreateAsset(id string, color string, size int, owner string, appraisedValue int)
 */
class IssueCertificateWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.txIndex = 0;
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.workerIndex = workerIndex;
        this.txIndex = 0;
    }

    async submitTransaction() {
        this.txIndex++;
        const assetID = `asset_w${this.workerIndex}_t${this.txIndex}_${Date.now()}`;

        const request = {
            contractId: 'basic',
            contractFunction: 'CreateAsset',
            contractArguments: [
                assetID,        // id (string)
                'blue',         // color (string)
                '5',            // size (int - passed as string, Fabric SDK converts)
                'CertOwner',    // owner (string)
                '300'           // appraisedValue (int - passed as string)
            ],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new IssueCertificateWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
