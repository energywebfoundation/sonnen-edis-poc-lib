pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../contracts/Asset/AssetProducingDB.sol";


contract SonnenAssetProducingDB is AssetProducingDB {

    struct MarketProperties {
        uint supplyId;
        uint timeFrameFrom;
        uint timeFrameTo;
        uint averagePower;
        bool supplyIdSet;
        string powerProfileURL;
        address marketLookupAddress;
        address certificateOwner;
    }

    struct SonnenAsset {
        AssetGeneral assetGeneral;
        MarketProperties marketProps;
        uint maxOwnerChanges;
    }

    /// @dev mapping for smartMeter-address => Asset
    mapping(address => SonnenAsset) internal assetMapping;

    constructor(address _assetLogic) AssetProducingDB(_assetLogic) public {}

    /// @notice gets the AssetGeneral-struct as storage-pointer
    /// @dev function has to be implemented in order to create a deployable bytecode
    /// @param _assetId the assetId of the AssetGeneral-struct to be returned
    /// @return returns a storage pointer to a AssetGeneral struct
    function getAssetGeneralInternal(uint _assetId) internal view returns (AssetGeneral storage general){
        return  assetMapping[smartMeterAddresses[_assetId]].assetGeneral;
    }

	/// @notice adds a complete sset to the mapping and array
	/// @param _a the complete asset
	/// @return the generated assetId
    function addFullSonnenAsset(SonnenAsset memory _a)
        public
        onlyOwner
        returns (uint _assetId)
    {
        _assetId = smartMeterAddresses.length;
        address smartMeter = _a.assetGeneral.smartMeter;
        assetMapping[smartMeter] = _a;
        smartMeterAddresses.push(smartMeter);
    }
    
    /// @notice gets an asset by its id
	/// @param _assetId the id of an asset
	/// @return Asset-struct
    function getSonnenAssetById(uint _assetId) external view returns (SonnenAsset memory) {
        return assetMapping[smartMeterAddresses[_assetId]];
    }

	/// @notice gets an asset by its smartmeter
	/// @param _smartMeter the smartmeter of an asset
	/// @return Asset-Struct
    function getSonnenAssetBySmartMeter(address _smartMeter) external onlyOwner view returns (SonnenAsset memory) {
        return assetMapping[_smartMeter];
    }

    function setMarketProperties(uint _assetId, MarketProperties memory _marketProps) public onlyOwner {
        assetMapping[smartMeterAddresses[_assetId]].marketProps = _marketProps;
    }

    function getMarketProperties(uint _assetId) external onlyOwner view returns (MarketProperties memory){
        return assetMapping[smartMeterAddresses[_assetId]].marketProps;
    }

}