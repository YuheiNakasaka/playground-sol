//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Coin {
  // publicにするとgetterが自動で生成される
  address public minter;
  mapping (address => uint256) public balances;
  
  event Sent(address from, address to, uint256 amount);

  constructor() {
    minter = msg.sender;
  } 

  function mint(address receiver, uint256 amount) public {
    require(msg.sender == minter);
    require(amount < 1e60, "Invalid amount.");
    balances[receiver] += amount;
  }

  function send(address receiver, uint amount) public {
    require(amount <= balances[msg.sender], "Insufficient balance.");
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    emit Sent(msg.sender, receiver, amount);
  }
}