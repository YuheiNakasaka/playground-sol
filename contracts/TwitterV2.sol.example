//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./TwitterV1.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TwitterV2 is TwitterV1 {
    bool initializedV2;

    function initializeV2() public {
        require(!initializedV2);
        initializedV2 = true;
    }
}
