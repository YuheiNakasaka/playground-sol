//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TwitterV1 is Initializable {
  struct Tweet {
    string content;
    address author;
    uint timestamp;
  }

  struct User {
    address id;
  }

  Tweet[] public tweets;
  mapping(address => User[]) public followings;
  mapping(address => User[]) public followers;
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {}

  function setTweet(string memory _tweet) public {
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
  }

  function getTimeline(int offset, int limit) public view returns (Tweet[] memory) {
    require(offset >= 0, "Offset must be greater than or equal to 0.");

    if (uint(offset) > tweets.length) {
      return new Tweet[](0);
    }

    int tweetLength = int(tweets.length);
    int length = tweetLength - offset > limit ? limit : tweetLength - offset;
    Tweet[] memory result = new Tweet[](uint(length));
    uint idx = 0;
    for (int i = length - offset - 1; length - offset - limit <= i; i--) {
      if (i <= length - offset - 1 && length - offset - limit <= i && i >= 0) {
        result[idx] = tweets[uint(i)];
        idx++;
      }
    }
    return result;
  }

  function getUserTweets(address _address) public view returns (Tweet[] memory) {
    uint count = 0;
    for (uint256 i = 0; i < tweets.length; i++) {
      if (tweets[i].author == _address) {
        count++;
      }
    }

    Tweet[] memory result = new Tweet[](count);
    uint idx = 0;
    for (int i = int(tweets.length - 1); 0 <= i; i--) {
      if (tweets[uint(i)].author == _address) {
        result[idx] = tweets[uint(i)];
        idx++;
      }
    }

    return result;
  }

  function follow(address _address) public {
    require(_address != msg.sender, "You cannot follow yourself.");

    bool exists = false;
    for (uint256 i = 0; i < followings[msg.sender].length; i++) {
      if (followings[msg.sender][i].id == _address) {
        exists = true;
      }
    }
    if (!exists) {
      followings[msg.sender].push(User({id: _address}));
    }

    exists = false;
    for (uint256 i = 0; i < followers[_address].length; i++) {
      if (followers[_address][i].id == msg.sender) {
        exists = true;
      }
    }
    if (!exists) {
      followers[_address].push(User({id: msg.sender}));
    }
  }

  function unfollow(address _address) public {
    require(_address != msg.sender, "You cannot unfollow yourself.");

    for (uint256 i = 0; i < followings[msg.sender].length; i++) {
      if (followings[msg.sender][i].id == _address) {
        for (uint j = i; j < followings[msg.sender].length - 1; j++) {
            followings[msg.sender][j] = followings[msg.sender][j + 1];
        }
        followings[msg.sender].pop();
      }
    }

    for (uint256 i = 0; i < followers[_address].length; i++) {
      if (followers[_address][i].id == msg.sender) {
        for (uint j = i; j < followers[_address].length - 1; j++) {
            followers[_address][j] = followers[_address][j + 1];
        }
        followers[_address].pop();
      }
    }
  }

  function getFollowings(address _address) public view returns (User[] memory) {
    return followings[_address];
  }

  function getFollowers(address _address) public view returns (User[] memory) {
    return followers[_address];
  }

  function isFollowing(address _address) public view returns (bool) {
    bool _following = false;
    for (uint256 i = 0; i < followings[msg.sender].length; i++) {
      if (followings[msg.sender][i].id == _address) {
        return true;
      }
    }
    return _following;
  }
}