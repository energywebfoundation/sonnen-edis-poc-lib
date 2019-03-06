import "../../contracts/Asset/AssetProducingRegistryLogic.sol";
import "../../contracts/Asset/SonnenAssetProducingDB.sol";
import "../../contracts/Interfaces/SonnenAssetProducingInterface.sol";
import "ew-market-contracts/contracts/Interfaces/MarketContractLookupInterface.sol";

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


contract SonnenProducingAssetLogic is AssetProducingRegistryLogic, SonnenAssetProducingInterface {

    /// @notice Constructor
    /// @param _userContractLookup usercontract-lookup-contract
    /// @param _assetContractLookup the asset-lookup-contract
    constructor(
        UserContractLookupInterface _userContractLookup, 
        AssetContractLookupInterface _assetContractLookup
    ) 
        public AssetProducingRegistryLogic(_userContractLookup, _assetContractLookup)
    {
    }

    
    function createSonnenAsset(
        address _smartMeter,
        address _owner,
        bool _active,
        address[] calldata _matcher,
        string calldata _propertiesDocumentHash,
        string calldata _url,
        uint _numOwnerChanges,
        address _marketLookupAddress
    )
        external
        isInitialized
        returns (uint _assetId)
    {
        SonnenAssetProducingDB.MarketProperties memory tempMarketProps = SonnenAssetProducingDB.MarketProperties({
            supplyId: 0,
            timeFrameFrom: 0,
            timeFrameTo: 0,
            averagePower: 0,
            baselinePower: 0,
            supplyIdSet: false,
            marketLookupAddress: _marketLookupAddress,
            powerProfileURL: "",
            certificateOwner: address(0x0)
        });

        checkBeforeCreation(_matcher, _owner, _smartMeter);

        AssetGeneral memory a = AssetGeneral({
            smartMeter: _smartMeter,
            owner: _owner,
            lastSmartMeterReadWh: 0,
            active: true,
            lastSmartMeterReadFileHash: "",
            matcher: _matcher,
            propertiesDocumentHash: _propertiesDocumentHash,
            url: _url,
            marketLookupContract: address(0x0),
            bundled: false
        });

        SonnenAssetProducingDB.SonnenAsset memory _asset = SonnenAssetProducingDB.SonnenAsset(
            {assetGeneral: a,
            maxOwnerChanges: _numOwnerChanges,
            marketProps: tempMarketProps
            }
        );

        _assetId = SonnenAssetProducingDB(address(db)).addFullSonnenAsset(_asset);

        emit LogAssetCreated(msg.sender, _assetId);

    }
    
    /// @notice gets an asset by its id
	/// @param _assetId the id of an asset
	/// @return Asset-struct
    function getSonnenAssetById(uint _assetId) external view returns (SonnenAssetProducingDB.SonnenAsset memory) {
        return SonnenAssetProducingDB(address(db)).getSonnenAssetById(_assetId);
    }

	/// @notice gets an asset by its smartmeter
	/// @param _smartMeter the smartmeter of an asset
	/// @return Asset-Struct
    function getSonnenAssetBySmartMeter(address _smartMeter) external onlyOwner view returns (SonnenAssetProducingDB.SonnenAsset memory) {
        return SonnenAssetProducingDB(address(db)).getSonnenAssetBySmartMeter(_smartMeter);
    }

    /// @notice Logs meter read
	/// @param _assetId The id belonging to an entry in the asset registry
	/// @param _newMeterRead The current meter read of the asset
	/// @param _lastSmartMeterReadFileHash Last meter read file hash
    function saveSmartMeterRead(
        uint _assetId,
        uint _newMeterRead,
        string calldata _lastSmartMeterReadFileHash
    )
        external
        isInitialized
    {
        require(false,"saveSmartMeterRead not supported for sonnen asset!");
    }

    function saveSonnenSmartMeterRead(
        uint _assetId,
        uint _newMeterRead,
        string calldata _lastSmartMeterReadFileHash,
        uint _timeFrameFrom,
        uint _timeFrameTo,
        uint _averagePower,
        uint _baselinePower,
        string calldata _powerProfileURL
    )
        external
        isInitialized
    {

        SonnenAssetProducingDB.MarketProperties memory tempMarketProps = SonnenAssetProducingDB(address(db)).getMarketProperties(_assetId);

        tempMarketProps.timeFrameFrom= _timeFrameFrom;
        tempMarketProps.timeFrameTo = _timeFrameTo;
        tempMarketProps.averagePower = _averagePower;
        tempMarketProps.baselinePower = _baselinePower;
        tempMarketProps.powerProfileURL = _powerProfileURL;
        SonnenAssetProducingDB(address(db)).setMarketProperties(_assetId, tempMarketProps);

        uint createdPower = setSmartMeterReadInternal(_assetId, _newMeterRead, _lastSmartMeterReadFileHash);
        SonnenAssetProducingDB.SonnenAsset memory asset = SonnenAssetProducingDB(address(db)).getSonnenAssetById(_assetId);

        if(address(asset.assetGeneral.marketLookupContract) != address(0x0)){
                TradableEntityInterface(OriginContractLookupInterface(asset.assetGeneral.marketLookupContract).originLogicRegistry()).createTradableEntity(
                    _assetId,
                    createdPower
                );
        }

        // we reset the supply binding
        tempMarketProps.supplyId =0;
        tempMarketProps.supplyIdSet = false;
        tempMarketProps.certificateOwner = address(0x0);

        SonnenAssetProducingDB(address(db)).setMarketProperties(_assetId, tempMarketProps);

    }

    function addSonnenAssetToSupply(uint _assetId, uint _supplyId) 
        external 
    {
        SonnenAssetProducingDB.MarketProperties memory tempMarketProps = SonnenAssetProducingDB(address(db)).getMarketProperties(_assetId);
        require(address(MarketContractLookupInterface(tempMarketProps.marketLookupAddress).marketLogicRegistry()) == msg.sender,"not the marketRegistry-contract");
        
        require(!tempMarketProps.supplyIdSet, "supply already set");
        
        tempMarketProps.supplyId = _supplyId;
        tempMarketProps.supplyIdSet = true;

        SonnenAssetProducingDB(address(db)).setMarketProperties(_assetId, tempMarketProps);
    }

    function setMarketPropsCertOwner(uint _assetId, address _owner)
        external 
        {
        SonnenAssetProducingDB.MarketProperties memory tempMarketProps = SonnenAssetProducingDB(address(db)).getMarketProperties(_assetId);
        require(address(MarketContractLookupInterface(tempMarketProps.marketLookupAddress).marketLogicRegistry()) == msg.sender,"not the marketRegistry-contract");

        require(owner != address(0x0), "owner cannot be 0");
        tempMarketProps.certificateOwner = _owner;
        SonnenAssetProducingDB(address(db)).setMarketProperties(_assetId, tempMarketProps);

    }

    function clearSonnenAsset(uint _assetId) external {

        SonnenAssetProducingDB.MarketProperties memory tempMarketProps = SonnenAssetProducingDB(address(db)).getMarketProperties(_assetId);

        require(address(MarketContractLookupInterface(tempMarketProps.marketLookupAddress).marketLogicRegistry()) == msg.sender,"not the marketRegistry-contract");

        // we reset the supply binding
        tempMarketProps.supplyId = 0;
        tempMarketProps.supplyIdSet = false;
        tempMarketProps.certificateOwner = address(0x0);
        SonnenAssetProducingDB(address(db)).setMarketProperties(_assetId, tempMarketProps);
    }

	/// @notice checks whether an assets with the provided smartmeter already exists
	/// @param _smartMeter smartmter of an asset
	/// @return whether there is already an asset with that smartmeter
    function checkAssetExist(address _smartMeter) public view returns (bool){
        return checkAssetGeneralExistingStatus(SonnenAssetProducingDB(address(db)).getSonnenAssetBySmartMeter(_smartMeter).assetGeneral);
    }

}