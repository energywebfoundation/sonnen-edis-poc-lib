import Web3 from 'web3';
import * as fs from 'fs';
import { migrateUserRegistryContracts } from 'ew-user-registry-contracts';
import { migrateSonnenAssetRegistryContracts } from 'ew-asset-registry-contracts';
import { migrateMarketRegistryContracts } from 'ew-market-contracts';
import { migrateSonnenContracts } from 'ew-origin-contracts';

const main = async () => {
    const configFile = JSON.parse(fs.readFileSync(process.cwd() + '/connection-config.json', 'utf8'));
    const web3 = new Web3(configFile.develop.web3);

    const privateKeyDeployment = configFile.develop.deployKey;

    /// User
    const userContracts = await migrateUserRegistryContracts(web3, privateKeyDeployment);
    const userContractLookupAddr = (userContracts as any).UserContractLookup;

    /// Asset
    const assetContracts = await migrateSonnenAssetRegistryContracts(web3, userContractLookupAddr, privateKeyDeployment);
    const assetRegistryLookupAddr = (assetContracts as any).AssetContractLookup;

    const originContracts = await migrateSonnenContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);

    const marketContracts = await migrateMarketRegistryContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);

    const deployedContracts = {};
    Object.keys(userContracts).forEach((key) => deployedContracts[key] = userContracts[key]);
    Object.keys(assetContracts).forEach((key) => deployedContracts[key] = assetContracts[key]);
    Object.keys(originContracts).forEach((key) => deployedContracts[key] = originContracts[key]);
    Object.keys(marketContracts).forEach((key) => deployedContracts[key] = marketContracts[key]);

    const writeJsonFile = require('write-json-file');
    await writeJsonFile('./config/contractConfig.json', deployedContracts);
};

main();