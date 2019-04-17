import Web3 from 'web3';
import * as fs from 'fs';
import contractConfig from '../config/contractConfig.json';
import * as Asset from 'ew-asset-registry-lib';
import { logger } from './Logger';
import { UserLogic } from 'ew-user-registry-contracts';
import { SonnenProducingAssetLogic } from 'ew-asset-registry-contracts';
import { MarketLogic } from 'ew-market-contracts';
import { EnergyLogic } from 'ew-origin-contracts';

const main = async () => {
    const configFile = JSON.parse(fs.readFileSync(process.cwd() + '/connection-config.json', 'utf8'));
    const web3 = new Web3(configFile.develop.web3);

    const privateKeyDeployment = configFile.develop.deployKey.startsWith('0x') ?
        configFile.develop.deployKey : '0x' + configFile.develop.deployKey;

    const accountDeployment = web3.eth.accounts.privateKeyToAccount(privateKeyDeployment).address;

    const assetOwnerPK = '0xfaab95e72c3ac39f7c060125d9eca3558758bb248d1a4cdc9c1b7fd3f91a4485';
    const assetOwnerAddress = web3.eth.accounts.privateKeyToAccount(assetOwnerPK).address;

    const assetSmartmeterPK = '0x2dc5120c26df339dbd9861a0f39a79d87e0638d30fdedc938861beac77bbd3f5';
    const assetSmartmeter = web3.eth.accounts.privateKeyToAccount(assetSmartmeterPK).address;

    const matcherPK = '0xc118b0425221384fe0cbbd093b2a81b1b65d0330810e0792c7059e518cea5383';
    const matcher = web3.eth.accounts.privateKeyToAccount(matcherPK).address;

    const assetSmartmeter2PK = '0x554f3c1470e9f66ed2cf1dc260d2f4de77a816af2883679b1dc68c551e8fa5ed';
    const assetSmartMeter2 = web3.eth.accounts.privateKeyToAccount(assetSmartmeter2PK).address;

    const userLogic = new UserLogic(web3, contractConfig.UserLogic);

    await userLogic.setUser(assetOwnerAddress, 'Sonnen', { privateKey: privateKeyDeployment });
    await userLogic.setRoles(assetOwnerAddress, 63, { privateKey: privateKeyDeployment });

    await userLogic.setUser(accountDeployment, 'admin', { privateKey: privateKeyDeployment });

    await userLogic.setRoles(accountDeployment, 3, { privateKey: privateKeyDeployment });

    const assetProps: Asset.ProducingAsset.OnChainProperties = {
        smartMeter: { address: assetSmartmeter },
        owner: { address: assetOwnerAddress },
        lastSmartMeterReadWh: 0,
        active: true,
        lastSmartMeterReadFileHash: 'lastSmartMeterReadFileHash',
        matcher: [{ address: matcher }],
        propertiesDocumentHash: null,
        url: null,
        maxOwnerChanges: 3,
        marketLookupAddress: contractConfig.MarketContractLookup,
    };

    const assetPropsOffChain: Asset.ProducingAsset.OffChainProperties = {
        operationalSince: Math.floor(Date.now() / 1000),
        capacityWh: 10000,
        country: 'Germany',
        region: 'Saxony',
        zip: '09648',
        city: 'Mittweida',
        street: 'Markt',
        houseNumber: '16 ',
        gpsLatitude: '50.985483',
        gpsLongitude: '12.981649',
        assetType: Asset.ProducingAsset.Type.Battery,
        complianceRegistry: Asset.ProducingAsset.Compliance.EEC,
        otherGreenAttributes: 'n.a',
        typeOfPublicSupport: 'n.a',
    };

    const conf = {
        blockchainProperties: {
            activeUser: {
                address: assetOwnerAddress, privateKey: assetOwnerPK,
            },
            producingAssetLogicInstance: new SonnenProducingAssetLogic(web3, contractConfig.AssetProducingRegistryLogic),
            userLogicInstance: new UserLogic(web3, contractConfig.UserLogic),
            web3,
        },
        offChainDataSource: {
            baseUrl: 'http://localhost:3030',
        },
        logger,
    };

    const asset = await Asset.ProducingAsset.createAsset(assetProps, assetPropsOffChain, conf);

    const assetRegistry = new SonnenProducingAssetLogic((web3 as any), contractConfig.AssetProducingRegistryLogic);
    const marketLogic = new MarketLogic(web3, contractConfig.MarketLogic);

    const traderPK = '0x2dc5120c26df339dbd9861a0f39a79d87e0638d30fdedc938861beac77bbd3f5';
    const accountTrader = web3.eth.accounts.privateKeyToAccount(traderPK).address;
    await userLogic.setUser(accountTrader, 'trader', { privateKey: privateKeyDeployment });
    await userLogic.setRoles(accountTrader, 63, { privateKey: privateKeyDeployment });

    await assetRegistry.setMarketLookupContract((Number(asset.id)), contractConfig.OriginContractLookup, { privateKey: assetOwnerPK });

    await marketLogic.createDemand('Saxonia', Date.now(), Date.now() + 1000, 1000, { privateKey: traderPK });
    await marketLogic.createSupply(0, 'Saxonia', Date.now(), Date.now() + 1000, 1000, 100, { privateKey: assetOwnerPK });
    await marketLogic.createAgreement(0, 0, { privateKey: traderPK });
    await assetRegistry.saveSonnenSmartMeterRead(
        0,
        500,
        'lastSmartMeterReadFileHash',
        Math.floor(Date.now() / 1000) - 1000,
        Math.floor(Date.now() / 1000),
        10,
        'url',
        { privateKey: assetSmartmeterPK });

    const assetProps2: Asset.ProducingAsset.OnChainProperties = {
        smartMeter: { address: assetSmartMeter2 },
        owner: { address: assetOwnerAddress },
        lastSmartMeterReadWh: 0,
        active: true,
        lastSmartMeterReadFileHash: 'lastSmartMeterReadFileHash',
        matcher: [{ address: matcher }],
        propertiesDocumentHash: null,
        url: null,
        maxOwnerChanges: 3,
        marketLookupAddress: contractConfig.MarketContractLookup,
    };
    assetProps.smartMeter = { address: assetSmartMeter2 };
    const asset2 = await Asset.ProducingAsset.createAsset(assetProps2, assetPropsOffChain, conf);
    await assetRegistry.setMarketLookupContract((Number(asset2.id)), contractConfig.OriginContractLookup, { privateKey: assetOwnerPK });

    const energyLogic = new EnergyLogic(web3, contractConfig.SonnenLogic);

    console.log(await energyLogic.getEnergyCertificateStruct(0));

    console.log(await energyLogic.getReportedFlexibility(0));

};

main();