// Copyright 2018 Energy Web Foundation
// This file is part of the Origin Application brought to you by the Energy Web Foundation,
// a global non-profit organization focused on accelerating blockchain technology across the energy sector,
// incorporated in Zug, Switzerland.
//
// The Origin Application is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// This is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY and without an implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details, at <http://www.gnu.org/licenses/>.
//
// @authors: slock.it GmbH; Martin Kuechler, martin.kuchler@slock.it; Heiko Burkhardt, heiko.burkhardt@slock.it

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "../../contracts/Trading/MarketDB.sol";
import "ew-user-registry-contracts/contracts/Users/RoleManagement.sol";
import "ew-utils-general-contracts/contracts/Interfaces/Updatable.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetGeneralInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetProducingInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetConsumingInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetContractLookupInterface.sol";
import "../../contracts/Interfaces/MarketContractLookupInterface.sol";
import "../../contracts/Interfaces/AgreementLogicInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/SonnenAssetProducingInterface.sol";

contract AgreementLogic is RoleManagement, Updatable, AgreementLogicInterface {

    event LogAgreementFullySigned(uint indexed _agreementId, uint indexed _demandId, uint indexed _supplyId);
    event LogAgreementCreated(uint indexed _agreementId, uint indexed _demandId);

    /// @notice database contract
    MarketDB public db;

    AssetContractLookupInterface public assetContractLookup;

    /// @notice constructor
    constructor(
        AssetContractLookupInterface _assetContractLookup,
        MarketContractLookupInterface _marketContractLookup
    )
        RoleManagement(UserContractLookupInterface(_assetContractLookup.userRegistry()), address(_marketContractLookup))
        public
    {
        assetContractLookup = _assetContractLookup;
    }

	/// @notice Function to create a agreement
	/// @dev will return an event with the event-Id
	/// @param _demandId the demand Id
    function createAgreement(
        uint _demandId,
        uint _supplyId
    )
        public
    { 
        uint[] memory supplyInternal = new uint[](1); 
        
        supplyInternal[0] = _supplyId;   

        uint agreementId = db.createAgreementDB(
            _demandId,
            supplyInternal
        );

        for(uint j = 0; j < supplyInternal.length; j++){
            MarketDB.Supply memory supply = db.getSupply(supplyInternal[j]);

            for(uint i = 0; i < supply.assetId.length; i++){
                SonnenAssetProducingInterface(assetContractLookup.assetProducingRegistry()).setMarketPropsCertOwner(supply.assetId[i], msg.sender);
            }
        }

    }

    function abortSupply(uint _supplyId) 
        external 
    {
        AgreementDB.SupplyAgreement memory sa = db.getAgreementForSupply(_supplyId);
        require(!sa.isSet, "supply is part of an agreeent");
        MarketDB.Supply memory supply = db.getSupply(_supplyId);

        for(uint i = 0; i < supply.assetId.length; i++){
            SonnenAssetProducingInterface(assetContractLookup.assetProducingRegistry()).clearSonnenAsset(supply.assetId[i]);
        }

    }

    function getAgreementForSupply(uint _supplyId) 
        external
        view 
        returns (uint _agreementId)
    {
        AgreementDB.SupplyAgreement memory sa = db.getAgreementForSupply(_supplyId);
        require(sa.isSet,"no agreement found");
        return getAgreementForSupplyPublic(_supplyId);
    } 

	/// @notice fuction to set the database contract, can only be called once
	/// @param _database the database contract
	/// @param _admin the admin
    function init(address _database, address _admin)
        public
        onlyOwner
    {
        require(address(db) == address(0x0),"init: already initialize");
        db = MarketDB(_database);
    }

	/// @notice Updates the logic contract
	/// @param _newLogic Address of the new logic contract
    function update(address _newLogic)
        external
        onlyOwner
    {
        db.changeOwner(_newLogic);
    }

	/// @notice get all agreement list length
	/// @return length of the allAgreements-array
    function getAllAgreementListLength() external view returns (uint) {
        return db.getAllAgreementListLengthDB();
    }


    function getAgreementStruct(uint _agreementId)
        external
        view
        returns (MarketDB.Agreement memory)
    {        
        return db.getAgreementDB(_agreementId);
    }

    function getAgreement(uint _agreementId)
        public
        view
        returns (
            uint _demandId,
            uint _supplyIds
        )
    {
        MarketDB.Agreement memory agreement = db.getAgreementDB(_agreementId);
        _demandId = agreement.demandId;
        _supplyIds = agreement.supplyId[0];
    }

    function getAgreementForSupplyPublic(uint _supplyId) 
        public
        view 
        returns (uint _agreementId)
    {
        AgreementDB.SupplyAgreement memory sa = db.getAgreementForSupply(_supplyId);
        require(sa.isSet,"no agreement found");
        return sa.agreementId;
    } 

    function getDemandForAgreementPublic(uint _agreementId) public view returns (uint _demandId){
        MarketDB.Agreement memory a = db.getAgreementDB(_agreementId);
        return a.demandId; 
    }

  /*
	/// @notice approves a demand for an agreement
	/// @param _agreementId the agreement Id
    function approveAgreementDemand(uint _agreementId)
        public
    {
        MarketDB.Agreement memory agreement = db.getAgreementDB(_agreementId);
   //     require(db.getDemand(agreement.demandId).demandOwner == msg.sender, "approveAgreementDemand: wrong msg.sender");

        // we approve a demand. If it's returning true it means that both supply and demand are approved thus making the agreement complete
        if(db.approveAgreementDemandDB(_agreementId)) {
            emit LogAgreementFullySigned(_agreementId, agreement.demandId, agreement.supplyId);
        }
    }

  
	/// @notice approves a supply for an agreement
	/// @param _agreementId the agreement Id
    function approveAgreementSupply(uint _agreementId)
        public
    {
        MarketDB.Agreement memory agreement = db.getAgreementDB(_agreementId);
        MarketDB.Supply memory supply = db.getSupply(agreement.supplyId);

        require(AssetGeneralInterface(assetContractLookup.assetProducingRegistry()).getAssetOwner(supply.assetId) == msg.sender, "approveAgreementSupply: wrong msg.sender");

        // we approve a supply. If it's returning true it means that both supply and demand are approved thus making the agreement complete
        if(db.approveAgreementSupplyDB(_agreementId)){
            emit LogAgreementFullySigned(_agreementId, agreement.demandId, agreement.supplyId);
        }
    }

    /// @notice sets the matcher for an agreement
    /// @dev can only be called as long as there are no matchers set
    /// @param _agreementId the agreement-Id
    function setAgreementMatcher(uint _agreementId) 
        internal 
    {
        MarketDB.Agreement memory agreement = db.getAgreementDB(_agreementId);

        assert(agreement.allowedMatcher.length == 0);
        MarketDB.Supply memory supply = db.getSupply(agreement.supplyId);

        (,,,,,address[] memory matcherArray,,,,) = AssetGeneralInterface(assetContractLookup.assetProducingRegistry()).getAssetGeneral(supply.assetId);

        db.setAgreementMatcher( _agreementId, matcherArray);
    }

    /// @notice allows matcher to change the matcher-properties for an agreement
    /// @param _agreementId the agreement-ID
    /// @param _matcherPropertiesDocumentHash document-hash of the matcher properties
    /// @param _matcherDBURL db-url of the document-hash
    function setMatcherProperties(
        uint _agreementId,
        string calldata _matcherPropertiesDocumentHash,
        string calldata _matcherDBURL
    )
        external
    {
        MarketDB.Agreement memory agreement = db.getAgreementDB(_agreementId);

        require(agreement.approvedBySupplyOwner, "supply owner has not agreed yet");
        require(agreement.approvedByDemandOwner, "demand owner has not agreed yet");
        address[] memory agreementMatcher = agreement.allowedMatcher;
        
        bool foundMatcher = false;

        // we have to check all the matchers
        for(uint i=0; i < agreementMatcher.length; i++){

            if ( agreementMatcher[i] == msg.sender) {
                foundMatcher = true;
                break;
            }
        }

        require(foundMatcher, "sender is not in matcher array");

        db.setMatcherPropertiesAndURL(_agreementId, _matcherPropertiesDocumentHash, _matcherDBURL);
    
    }
    */
}