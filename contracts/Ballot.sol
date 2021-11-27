//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Ballot {
  // 投票者
  struct Voter {
    uint weight;
    bool voted;
    address delegate;
    uint vote;
  }

  // 投票対象の提案
  struct Proposal {
    bytes32 name;
    uint voteCount;
  }

  // owner
  address public chairperson;

  // 投票者とそのアドレスのmap
  mapping(address => Voter) public voters;

  Proposal[] public proposals;

  constructor(bytes32[] memory proposalNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;

    // 各提案の初期化
    for (uint i = 0; i < proposalNames.length; i++){
      proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
    }
  }

  function getProposals() public view returns (Proposal[] memory){
    return proposals;
  }

  function giveRightToVote(address voter) external {
    require(msg.sender == chairperson, "Only chairperson can give right to vote");
    require(!voters[voter].voted, "The voter already voted");
    require(voters[voter].weight == 0);
    voters[voter].weight = 1;
  }

  // 自分(sender)の投票権をtoに委譲する
  function delegate(address to) external {
    Voter storage sender = voters[msg.sender];
    require(!sender.voted, "You already voted");
    require(to != msg.sender, "Self-delegation is disallowed.");

    while (voters[to].delegate != address(0)) {
      to = voters[to].delegate;
      require(to != msg.sender, "Found loop in delegation");
    }

    sender.voted = true;
    sender.delegate = to;
    Voter storage delegate_ = voters[to];
    if (delegate_.voted) {
      // 委譲された側が既に投票済みの場合は、単に委譲した人の分だけ投票数を増やせば良い
      proposals[delegate_.vote].voteCount += sender.weight;
    } else {
      // まだ誰にも投票してない場合は投票権を増やす
      delegate_.weight += sender.weight;
    }
  }

  function vote(uint proposal) external {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, "Has no right to vote.");
    require(!sender.voted, "Already voted.");
    // Storageの中身を更新
    sender.voted = true;
    sender.vote = proposal;
    proposals[proposal].voteCount += sender.weight;
  }

  function winningProposal() public view returns (uint winningProposal_){
    uint winningVoteCount = 0;
    for (uint p = 0; p < proposals.length; p++) {
      if (proposals[p].voteCount > winningVoteCount) {
        winningVoteCount = proposals[p].voteCount;
        winningProposal_ = p;
      }
    }
  }

  function winningName() external view returns(bytes32 winnerName_) {
    winnerName_ = proposals[winningProposal()].name;
  }
}