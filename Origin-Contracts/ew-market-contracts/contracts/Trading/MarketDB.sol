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

import "../../contracts/Trading/AgreementDB.sol";

/// @title The Database contract for the AgreementDB of Origin list
/// @notice This contract only provides getter and setter methods and only its logic-contract is able to call the functions
contract MarketDB is AgreementDB {

    /// @notice struct for gather all information
    struct Demand {
        string regionId;
        uint dateTimeFrom;
        uint dateTimeTo;
        uint power;
        uint matchedPower;
    }

    struct Supply {
        uint[] assetId;
        string regionId;
        uint dateTimeFrom;
        uint dateTimeTo;
        uint power;
        uint matchedPower;
        uint price;
    }

    /// @notice list with all created demands
    Demand[] private allDemands;

    /// @notice list with all supplies
    Supply[] private allSupply;

    /// @notice Constructor
    /// @param _owner The owner of the contract
    constructor(address _owner) public Owned(_owner) {}

	/// @notice creates a demand
	/// @return the demand-id
    function createDemand
    (
        string calldata _regionId,
        uint _dateTimeFrom,
        uint _dateTimeTo,
        uint _power,
        uint _matchedPower
    )
        external
        onlyOwner
        returns (uint _demandId)
    {
        allDemands.push(Demand({
            regionId: _regionId,
            dateTimeFrom: _dateTimeFrom,
            dateTimeTo: _dateTimeTo,
            power: _power,
            matchedPower: _matchedPower
        }));
        _demandId = allDemands.length>0?allDemands.length-1:0;
    }

	/// @notice creates a supply
    function createSupply
    (
        uint[] memory _assetId,
        string memory _regionId,
        uint _dateTimeFrom,
        uint _dateTimeTo,
        uint _power,
        uint _matchedPower,
        uint _price
    )
        public
        onlyOwner
        returns (uint _supplyId)
    {
        allSupply.push(Supply({
            assetId: _assetId,
            regionId: _regionId,
            dateTimeFrom: _dateTimeFrom,
            dateTimeTo: _dateTimeTo,
            power: _power,
            matchedPower: _matchedPower,
            price: _price
        }));
        _supplyId = allSupply.length>0?allSupply.length-1:0;
    }

	/// @notice funtion to retrieve the length of the demands-array
	/// @return the length of the allagreements-array
    function getAllDemandListLength()
        external
        view
        onlyOwner
        returns (uint)
    {
        return allDemands.length;
    }

	/// @notice funtion to retrieve the length of the supply-array
	/// @return the length of the allagreements-array
    function getAllSupplyListLength()
        external
        view
        onlyOwner
        returns (uint)
    {
        return allSupply.length;
    }



	/// @notice Returns a demand-struct
	/// @param _demandId id of a demand
	/// @return returns a demand-struct
    function getDemand(uint _demandId)
        external
        view
        onlyOwner
        returns (Demand memory)
    {
        return allDemands[_demandId];
    }

	/// @notice Returns a supply-struct
	/// @param _supplyId id of a supply
	/// @return returns a supply-struct
    function getSupply(uint _supplyId)
        external
        view
        onlyOwner
        returns (Supply memory)
    {
        return allSupply[_supplyId];
    }

    function setDemandMatchedPower(
        uint _demandId,
        uint _matchedPower
    )
        external 
        onlyOwner
    {
       
        Demand storage d = allDemands[_demandId];
        d.matchedPower = _matchedPower;
    }

    function setSupplyMatchedPower(
        uint _supplyId,
        uint _matchedPower
    )
        external
        onlyOwner
    {
        Supply storage s = allSupply[_supplyId];
        s.matchedPower = _matchedPower;
    }

}
