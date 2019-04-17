"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const web3_1 = __importDefault(require("web3"));
const fs = __importStar(require("fs"));
const contractConfig_json_1 = __importDefault(require("../config/contractConfig.json"));
const Asset = __importStar(require("ew-asset-registry-lib"));
const Logger_1 = require("./Logger");
const ew_user_registry_contracts_1 = require("ew-user-registry-contracts");
const ew_asset_registry_contracts_1 = require("ew-asset-registry-contracts");
const ew_market_contracts_1 = require("ew-market-contracts");
const ew_origin_contracts_1 = require("ew-origin-contracts");
const main = () => __awaiter(this, void 0, void 0, function* () {
    const configFile = JSON.parse(fs.readFileSync(process.cwd() + '/connection-config.json', 'utf8'));
    const web3 = new web3_1.default(configFile.develop.web3);
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
    const userLogic = new ew_user_registry_contracts_1.UserLogic(web3, contractConfig_json_1.default.UserLogic);
    yield userLogic.setUser(assetOwnerAddress, 'Sonnen', { privateKey: privateKeyDeployment });
    yield userLogic.setRoles(assetOwnerAddress, 63, { privateKey: privateKeyDeployment });
    yield userLogic.setUser(accountDeployment, 'admin', { privateKey: privateKeyDeployment });
    yield userLogic.setRoles(accountDeployment, 3, { privateKey: privateKeyDeployment });
    const assetProps = {
        smartMeter: { address: assetSmartmeter },
        owner: { address: assetOwnerAddress },
        lastSmartMeterReadWh: 0,
        active: true,
        lastSmartMeterReadFileHash: 'lastSmartMeterReadFileHash',
        matcher: [{ address: matcher }],
        propertiesDocumentHash: null,
        url: null,
        maxOwnerChanges: 3,
        marketLookupAddress: contractConfig_json_1.default.MarketContractLookup,
    };
    const assetPropsOffChain = {
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
            producingAssetLogicInstance: new ew_asset_registry_contracts_1.SonnenProducingAssetLogic(web3, contractConfig_json_1.default.AssetProducingRegistryLogic),
            userLogicInstance: new ew_user_registry_contracts_1.UserLogic(web3, contractConfig_json_1.default.UserLogic),
            web3,
        },
        offChainDataSource: {
            baseUrl: 'http://localhost:3030',
        },
        logger: Logger_1.logger,
    };
    const asset = yield Asset.ProducingAsset.createAsset(assetProps, assetPropsOffChain, conf);
    const assetRegistry = new ew_asset_registry_contracts_1.SonnenProducingAssetLogic(web3, contractConfig_json_1.default.AssetProducingRegistryLogic);
    const marketLogic = new ew_market_contracts_1.MarketLogic(web3, contractConfig_json_1.default.MarketLogic);
    const traderPK = '0x2dc5120c26df339dbd9861a0f39a79d87e0638d30fdedc938861beac77bbd3f5';
    const accountTrader = web3.eth.accounts.privateKeyToAccount(traderPK).address;
    yield userLogic.setUser(accountTrader, 'trader', { privateKey: privateKeyDeployment });
    yield userLogic.setRoles(accountTrader, 63, { privateKey: privateKeyDeployment });
    yield assetRegistry.setMarketLookupContract((Number(asset.id)), contractConfig_json_1.default.OriginContractLookup, { privateKey: assetOwnerPK });
    yield marketLogic.createDemand('Saxonia', Date.now(), Date.now() + 1000, 1000, { privateKey: traderPK });
    yield marketLogic.createSupply(0, 'Saxonia', Date.now(), Date.now() + 1000, 1000, 100, { privateKey: assetOwnerPK });
    yield marketLogic.createAgreement(0, 0, { privateKey: traderPK });
    yield assetRegistry.saveSonnenSmartMeterRead(0, 500, 'lastSmartMeterReadFileHash', Math.floor(Date.now() / 1000) - 1000, Math.floor(Date.now() / 1000), 10, 'url', { privateKey: assetSmartmeterPK });
    const assetProps2 = {
        smartMeter: { address: assetSmartMeter2 },
        owner: { address: assetOwnerAddress },
        lastSmartMeterReadWh: 0,
        active: true,
        lastSmartMeterReadFileHash: 'lastSmartMeterReadFileHash',
        matcher: [{ address: matcher }],
        propertiesDocumentHash: null,
        url: null,
        maxOwnerChanges: 3,
        marketLookupAddress: contractConfig_json_1.default.MarketContractLookup,
    };
    assetProps.smartMeter = { address: assetSmartMeter2 };
    const asset2 = yield Asset.ProducingAsset.createAsset(assetProps2, assetPropsOffChain, conf);
    yield assetRegistry.setMarketLookupContract((Number(asset2.id)), contractConfig_json_1.default.OriginContractLookup, { privateKey: assetOwnerPK });
    const energyLogic = new ew_origin_contracts_1.EnergyLogic(web3, contractConfig_json_1.default.SonnenLogic);
    console.log(yield energyLogic.getEnergyCertificateStruct(0));
    console.log(yield energyLogic.getReportedFlexibility(0));
});
main();
//# sourceMappingURL=asset.js.map