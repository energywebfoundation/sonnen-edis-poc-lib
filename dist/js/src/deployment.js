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
const ew_user_registry_contracts_1 = require("ew-user-registry-contracts");
const ew_asset_registry_contracts_1 = require("ew-asset-registry-contracts");
const ew_market_contracts_1 = require("ew-market-contracts");
const ew_origin_contracts_1 = require("ew-origin-contracts");
const main = () => __awaiter(this, void 0, void 0, function* () {
    const configFile = JSON.parse(fs.readFileSync(process.cwd() + '/connection-config.json', 'utf8'));
    const web3 = new web3_1.default(configFile.develop.web3);
    const privateKeyDeployment = configFile.develop.deployKey;
    /// User
    const userContracts = yield ew_user_registry_contracts_1.migrateUserRegistryContracts(web3, privateKeyDeployment);
    const userContractLookupAddr = userContracts.UserContractLookup;
    /// Asset
    const assetContracts = yield ew_asset_registry_contracts_1.migrateSonnenAssetRegistryContracts(web3, userContractLookupAddr, privateKeyDeployment);
    const assetRegistryLookupAddr = assetContracts.AssetContractLookup;
    const originContracts = yield ew_origin_contracts_1.migrateSonnenContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);
    const marketContracts = yield ew_market_contracts_1.migrateMarketRegistryContracts(web3, assetRegistryLookupAddr, privateKeyDeployment);
    const deployedContracts = {};
    Object.keys(userContracts).forEach((key) => deployedContracts[key] = userContracts[key]);
    Object.keys(assetContracts).forEach((key) => deployedContracts[key] = assetContracts[key]);
    Object.keys(originContracts).forEach((key) => deployedContracts[key] = originContracts[key]);
    Object.keys(marketContracts).forEach((key) => deployedContracts[key] = marketContracts[key]);
    const writeJsonFile = require('write-json-file');
    yield writeJsonFile('./config/contractConfig.json', deployedContracts);
});
main();
//# sourceMappingURL=deployment.js.map