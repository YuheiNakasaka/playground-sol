//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./TwitterV1.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TwitterV2 is TwitterV1 {
  bool initializedV2;

  event Tweeted(address indexed sender, string tweet);

  function initializeV2() public {
    require(!initializedV2);
    initializedV2 = true;
  }

  function setTweetV2(string memory _tweet) virtual public {
    require(bytes(_tweet).length > 0, "Tweet is too short");

    bool isSpaceOnly = true;
    for (uint i = 0; i < bytes(_tweet).length; i++) {
      bytes1 rune = bytes(_tweet)[i];
      if (rune != bytes1(" ")) {
        isSpaceOnly = false;
        break;
      }
    }
    require(!isSpaceOnly, "Space only tweet is not allowed.");

    tweets.push(Tweet({
      content: _tweet,
      author: msg.sender,
      timestamp: block.timestamp
    }));

    emit Tweeted(msg.sender, _tweet);
  }
}