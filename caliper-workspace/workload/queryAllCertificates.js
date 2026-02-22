'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

/**
 * Workload module for querying all certificates (GetAllAssets).
 * Uses the correct function name: GetAllAssets (NOT QueryAllCertificatesWithPagination).
 */
class QueryAllCertificatesWorkload extends WorkloadModuleBase {
    constructor() {
        super();
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
    }

    async submitTransaction() {
        const request = {
            contractId: 'basic',
            contractFunction: 'GetAllAssets',
            contractArguments: [],
            readOnly: true
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new QueryAllCertificatesWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
