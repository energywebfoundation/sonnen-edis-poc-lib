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

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../contracts/Asset/SonnenAssetProducingDB.sol";


/// @title this interface defines the functions of the AssetContractLookup-Contract
interface SonnenAssetProducingInterface {
    function addSonnenAssetToSupply(uint _assetId, uint _supplyId) external;    
	function getSonnenAssetById(uint _assetId) external view returns (SonnenAssetProducingDB.SonnenAsset memory);
    function setMarketPropsCertOwner(uint _assetId, address _owner) external;
    function clearSonnenAsset(uint _assetId) external;
}
