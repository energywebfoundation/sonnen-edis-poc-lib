import Web3 from 'web3';
import * as fs from 'fs';
import { migrateUserRegistryContracts } from 'ew-user-registry-contracts';
import { migrateSonnenAssetRegistryContracts } from 'ew-asset-registry-contracts-sonnen';
import { migrateMarketRegistryContracts } from 'ew-market-contracts-sonnen';
import { migrateSonnenContracts } from 'ew-origin-contracts-sonnen';
import { CONFIG } from './config';
import fetch from 'node-fetch';

const main = async () => {
    const configFile = JSON.parse(fs.readFileSync(process.cwd() + '/connection-config.json', 'utf8'));
    const web3 = new Web3(configFile.develop.web3);

    const privateKeyDeployment = configFile.develop.deployKey;

    /// User
    const userContracts = await migrateUserRegistryContracts(web3, privateKeyDeployment);
    const userContractLookupAddr = (userContracts as any).UserContractLookup;
    console.log('user contracts deployed');

    /// Asset
    const assetContracts = await migrateSonnenAssetRegistryContracts(web3, userContractLookupAddr, privateKeyDeployment);
    const assetRegistryLookupAddr = (assetContracts as any).AssetContractLookup;
    console.log('asset contracts deployed', assetContracts);

    const originContracts = await migrateSonnenContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);
    console.log('origin contracts deployed', originContracts);

    if (assetRegistryLookupAddr) {
        console.log('Posting to ', `${CONFIG.API_BASE_URL}/OriginContractLookupAssetLookupMapping/${originContracts['OriginContractLookup'].toLowerCase()}`);
        fetch(`${CONFIG.API_BASE_URL}/OriginContractLookupAssetLookupMapping/${originContracts['OriginContractLookup'].toLowerCase()}`, {
            body: JSON.stringify({
                assetContractLookup: assetRegistryLookupAddr.toLowerCase(),
            }),
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            }
        })
    }

    const marketContracts = await migrateMarketRegistryContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);
    console.log('market contracts deployed');

    const deployedContracts = {};
    Object.keys(userContracts).forEach((key) => deployedContracts[key] = userContracts[key]);
    Object.keys(assetContracts).forEach((key) => deployedContracts[key] = assetContracts[key]);
    Object.keys(originContracts).forEach((key) => deployedContracts[key] = originContracts[key]);
    Object.keys(marketContracts).forEach((key) => deployedContracts[key] = marketContracts[key]);

    const writeJsonFile = require('write-json-file');
    await writeJsonFile('./config/contractConfig.json', deployedContracts);
};

main();