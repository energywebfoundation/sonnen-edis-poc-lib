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
import "../../contracts/Trading/AgreementLogic.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/SonnenAssetProducingInterface.sol";
import "../../contracts/Interfaces/MarketLogicInterface.sol";

/// @title The logic contract for the AgreementDB of Origin list
contract MarketLogic is AgreementLogic, MarketLogicInterface {

    event createdNewDemand(address _sender, uint indexed _demandId);
    event createdNewSupply(address _sender, uint indexed _supplyId);

    /// @notice constructor
    constructor(
        AssetContractLookupInterface _assetContractLookup,
        MarketContractLookupInterface _marketContractLookup
    )
        AgreementLogic(_assetContractLookup,_marketContractLookup)
        public
    {
    }

	/// @notice Function to create a demand
	/// @dev will return an event with the event-Id
   function createDemand
    (
        string calldata _regionId,
        uint _dateTimeFrom,
        uint _dateTimeTo,
        uint _power
    )
        external
        onlyRole(RoleManagement.Role.Trader)
     {
        uint demandID = db.createDemand(_regionId, _dateTimeFrom, _dateTimeTo, _power, 0);
        emit createdNewDemand(msg.sender, demandID);
    }

	/// @notice Function to create a supply
	/// @dev will return an event with the event-Id
    function createSupply
    (
        uint _assetId,
        string memory _regionId,
        uint _dateTimeFrom,
        uint _dateTimeTo,
        uint _power,
        uint _price
    )
        public
     {
        uint[] memory assetIdInternal = new uint[](1); 
        
        assetIdInternal[0] = _assetId;         

     //   require(AssetGeneralInterface(assetContractLookup.assetProducingRegistry()).getAssetOwner(_assetId) == msg.sender, "wrong msg.sender");
        uint supplyID = db.createSupply(assetIdInternal, _regionId, _dateTimeFrom, _dateTimeTo, _power, 0, _price);

        for(uint i=0; i < assetIdInternal.length;i++){
           SonnenAssetProducingInterface(assetContractLookup.assetProducingRegistry()).addSonnenAssetToSupply(assetIdInternal[i], supplyID);
        }
        emit createdNewSupply(msg.sender, supplyID);


    }

	/// @notice function to return the length of the allDemands-array in the database
	/// @return length of the allDemansa-array
    function getAllDemandListLength() external view returns (uint) {
        return db.getAllDemandListLength();
    }

	/// @notice function to return the length of the allSupply-array in the database
	/// @return length of the allDemansa-array
    function getAllSupplyListLength() external view returns (uint) {
        return db.getAllSupplyListLength();
    }

	/// @notice Returns the information of a demand
	/// @param _demandId index of the demand in the allDemands-array
	/// @return propertiesDocumentHash, documentDBURL and owner
    function getDemand(uint _demandId)
        external
        view
        returns (
            string memory _regionId,
            uint _dataTimeFrom,
            uint _dateTimeTo,
            uint _power,
            uint _matchedPower
        )
    {
        MarketDB.Demand memory demand = db.getDemand(_demandId);
            _regionId = demand.regionId;
            _dataTimeFrom = demand.dateTimeFrom;
            _dateTimeTo = demand.dateTimeTo;
            _power = demand.power;
            _matchedPower = demand.matchedPower;
    }

    function getSupplyStruct(uint _supplyId) external view returns (MarketDB.Supply memory){
        return db.getSupply(_supplyId);
    }


	/// @notice gets a supply
	/// @param _supplyId the supply Id
	/// @return the supply
    function getSupply(uint _supplyId)
        public
        view
        returns (
            uint _assetId,
            string memory _regionId,
            uint _dateTimeFrom,
            uint _dateTimeTo,
            uint _power,
            uint _matchedPower,
            uint _price
        )
    {
        
        MarketDB.Supply memory supply = db.getSupply(_supplyId);
        _assetId = supply.assetId[0];
        _regionId = supply.regionId;
        _dateTimeFrom = supply.dateTimeFrom;
        _dateTimeTo = supply.dateTimeTo; 
        _power = supply.power;
        _matchedPower = supply.matchedPower;
        _price = supply.price;

        
    }

    function setDemandMatchedPower(
        uint _demandId,
        uint _power
    )
        external
    {
        MarketDB.Demand memory demand = db.getDemand(_demandId);

        // Overflow check
        assert(demand.matchedPower + _power >= demand.matchedPower);
        require(demand.matchedPower + _power <= demand.power,"too much power for demand");

        db.setDemandMatchedPower(_demandId, _power);
    }

    function setSupplyMatchedPower(
        uint _supplyId,
        uint _power
    )
        external
    {
        MarketDB.Supply memory supply = db.getSupply(_supplyId);

        // Overflow check
        assert(supply.matchedPower + _power >= supply.matchedPower);

        uint agreementId = getAgreementForSupplyPublic(_supplyId);
        
        uint demandId= db.getAgreementDB(agreementId).demandId;
        MarketDB.Demand memory demand = db.getDemand(demandId);
    
        uint powerStillOpen = demand.power - demand.matchedPower; 

        if(powerStillOpen >= _power) {
            db.setSupplyMatchedPower(_supplyId, supply.matchedPower +_power);
        } else {
            uint diff = _power - powerStillOpen;
            uint matchedPower = _power - diff;
            db.setSupplyMatchedPower(_supplyId,supply.matchedPower + matchedPower);
        }
    }

    function getDemandForAgreement(uint _agreementId) external view returns (uint _demandId){
         MarketDB.Agreement memory a = db.getAgreementDB(_agreementId);

         return a.demandId;
    }


}
