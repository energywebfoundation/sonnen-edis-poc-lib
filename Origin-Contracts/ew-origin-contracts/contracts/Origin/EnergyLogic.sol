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
// @authors: slock.it GmbH; Martin Kuechler, martin.kuchler@slock.it; Heiko Burkhardt, heiko.burkhardt@slock.it;

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "ew-asset-registry-contracts/contracts/Interfaces/SonnenAssetProducingInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetContractLookupInterface.sol";
import "ew-user-registry-contracts/contracts/Users/RoleManagement.sol";
import "../../contracts/Origin/TradableEntityContract.sol";
import "../../contracts/Origin/TradableEntityLogic.sol";
import "../../contracts/Interfaces/OriginContractLookupInterface.sol";
import "ew-asset-registry-contracts/contracts/Interfaces/AssetContractLookupInterface.sol";
import "../../contracts/Origin/EnergyDB.sol";
import "ew-market-contracts/contracts/Interfaces/MarketContractLookupInterface.sol";
import "ew-market-contracts/contracts/Interfaces/AgreementLogicInterface.sol";
import "ew-market-contracts/contracts/Interfaces/MarketLogicInterface.sol";

/// @title The logic contract for the AgreementDB of Origin list
contract EnergyLogic is RoleManagement, TradableEntityLogic, TradableEntityContract {


    event LogCreatedCertificate(uint indexed _certificateId, uint powerInW, address owner);
    event LogTest(address marketlookup, address marketLogic, uint agreementId, uint supplyId);

    event LogFlexibilityCreated( 
        uint id, 
        uint activationId, 
        uint dateTimeFrom, 
        uint dateTimeTo, 
        uint energyAmount, 
        uint averagePower,
         string powerProfileURL, 
         string powerProfileHash);

    /// @notice Constructor
    /// @param _assetContractLookup the assetRegistryContractRegistry-contract-address
    /// @param _originContractLookup the originContractLookup-contract-address
    constructor(
        AssetContractLookupInterface _assetContractLookup,
        OriginContractLookupInterface _originContractLookup
    )
        TradableEntityLogic(_assetContractLookup, _originContractLookup)
    public {

    }


    // @notice creates a new Entity / certificate
    /// @param _assetId the id of the producing asset
    /// @param _powerInW the generated power in Wh
    function createTradableEntity(
        uint _assetId, 
        uint _powerInW
    ) 
        external
        onlyAccount(address(assetContractLookup.assetProducingRegistry()))
        returns (uint _id)
    {        
        SonnenAssetProducingDB.SonnenAsset memory asset = SonnenAssetProducingInterface(address(assetContractLookup.assetProducingRegistry())).getSonnenAssetById(_assetId);

        uint agreementId = AgreementLogicInterface(MarketContractLookupInterface(asset.marketProps.marketLookupAddress).marketLogicRegistry()).getAgreementForSupply(asset.marketProps.supplyId);
        emit LogTest(asset.marketProps.marketLookupAddress, MarketContractLookupInterface(asset.marketProps.marketLookupAddress).marketLogicRegistry(), agreementId, asset.marketProps.supplyId);

        // Cert creation
        EnergyDB.Flexibility memory flex = EnergyDB.Flexibility({
            activationId:  agreementId,
            datetimeFrom: asset.marketProps.timeFrameFrom,	
            datetimeTo: asset.marketProps.timeFrameTo,
            energyAmountInWh: _powerInW,
            averagePowerInW: asset.marketProps.averagePower,
            powerProfileURL:  asset.marketProps.powerProfileURL,
            powerProfileHash: asset.assetGeneral.lastSmartMeterReadFileHash,
            reportConfirmed: false
        });

        _id = EnergyDB(address(db)).createTradableEntityEntry(
            _assetId,
            asset.marketProps.certificateOwner,
            _powerInW,
            flex
        );  

        emit LogCreatedCertificate(_id, _powerInW, asset.assetGeneral.owner);

        uint demandId = AgreementLogicInterface(MarketContractLookupInterface(asset.marketProps.marketLookupAddress).marketLogicRegistry()).getDemandForAgreement(agreementId);
        MarketLogicInterface(MarketContractLookupInterface(asset.marketProps.marketLookupAddress).marketLogicRegistry()).setSupplyMatchedPower(asset.marketProps.supplyId,_powerInW);

        MarketLogicInterface(MarketContractLookupInterface(asset.marketProps.marketLookupAddress).marketLogicRegistry()).setDemandMatchedPower(demandId,_powerInW);

        emit LogFlexibilityCreated( _id, agreementId, asset.marketProps.timeFrameFrom, asset.marketProps.timeFrameTo, _powerInW, asset.marketProps.averagePower, asset.marketProps.powerProfileURL, asset.assetGeneral.lastSmartMeterReadFileHash);
    
    }

    function approveCertificate(uint _certificateId)
        external
    {     
        EnergyDB.Energy memory energyCert = EnergyDB(address(db)).getEnergyCertificate(_certificateId);
        require(energyCert.tradableEntity.owner == msg.sender, "not the certificate owner");

        EnergyDB(address(db)).setApproved(_certificateId, true);
    }

    function getReportedFlexibility(uint _id)
        external 
        view
        returns (
            uint _activationId,
            uint _dateTimeFrom,
            uint _dateTimeTo,
            uint _energyAmount,
            uint _averagePower,
            string memory _powerProfileURL,
            string memory _powerProfileHash,
            bool _reportConfirmed
        )
    {
        EnergyDB.Energy memory energy =  EnergyDB(address(db)).getEnergyCertificate(_id);

        _activationId = energy.flexibility.activationId;
        _dateTimeFrom = energy.flexibility.datetimeFrom;
        _dateTimeTo = energy.flexibility.datetimeTo;
        _energyAmount = energy.flexibility.energyAmountInWh;
        _averagePower = energy.flexibility.averagePowerInW;
        _powerProfileURL = energy.flexibility.powerProfileURL;
        _powerProfileHash = energy.flexibility.powerProfileHash;
        _reportConfirmed = energy.flexibility.reportConfirmed;
    }

    function getEnergyCertificateStruct(uint _certId)
        external
        view 
        returns (EnergyDB.Energy memory)
    {
        return EnergyDB(address(db)).getEnergyCertificate(_certId);
    }

    function getCertificateListLength()
        external
        view
        returns (uint)
    {
        return EnergyDB(address(db)).getCertificateListLength();
    }


}
