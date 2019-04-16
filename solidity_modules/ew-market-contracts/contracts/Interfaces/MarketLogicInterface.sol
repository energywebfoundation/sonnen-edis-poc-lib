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

/// @title this interface defines the functions of the AssetContractLookup-Contract
interface MarketLogicInterface {
    
    function getDemand(uint _demandId) external view returns (string memory _regionId,uint _dataTimeFrom,uint _dateTimeTo,uint _power,uint _matchedPower);
    //function getSupply(uint _supplyId) external view returns (uint _assetId,string memory _regionId,uint _dateTimeFrom,uint _dateTimeTo,uint _power,uint _baselinePower,uint _matchedPower,uint _price);
    function setDemandMatchedPower(uint _demandId,uint _power) external;
    function setSupplyMatchedPower(uint _supplyId,uint _power) external;
    function getSupplyStruct(uint _supplyId) external view returns (MarketDB.Supply memory);
}