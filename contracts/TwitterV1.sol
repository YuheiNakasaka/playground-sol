//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./Base64.sol";
import "./TweetValidation.sol";
import "./TweetConstant.sol";

contract TwitterV1 is Initializable, ERC721EnumerableUpgradeable {
    struct Tweet {
        uint256 tokenId;
        string content;
        address author;
        uint256 timestamp;
        string attachment;
    }

    struct User {
        address id;
    }

    Tweet[] public tweets;
    mapping(address => User[]) public followings;
    mapping(address => User[]) public followers;

    event Tweeted(address indexed sender, string tweet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC721_init("Tweet", "TWT");
    }

    function initialize() public initializer {}

    function setTweet(string memory _tweet, string memory _imageData)
        public
        payable
        virtual
    {
        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        if (TweetValidation.notEmpty(_imageData)) {
            tweets.push(
                Tweet({
                    tokenId: tokenId,
                    content: _tweet,
                    author: msg.sender,
                    timestamp: block.timestamp,
                    attachment: _imageData
                })
            );
            _safeMint(msg.sender, supply + 1);
        } else {
            require(TweetValidation.notEmpty(_tweet), "Tweet is too short");
            require(
                TweetValidation.noSpace(_tweet),
                "Space only tweet is not allowed."
            );
            tweets.push(
                Tweet({
                    tokenId: tokenId,
                    content: _tweet,
                    author: msg.sender,
                    timestamp: block.timestamp,
                    attachment: ""
                })
            );
            _safeMint(msg.sender, supply + 1);
        }

        emit Tweeted(msg.sender, _tweet);
    }

    function getTimeline(int256 offset, int256 limit)
        public
        view
        virtual
        returns (Tweet[] memory)
    {
        require(offset >= 0, "Offset must be greater than or equal to 0.");

        if (uint256(offset) > tweets.length) {
            return new Tweet[](0);
        }

        int256 tweetLength = int256(tweets.length);
        int256 length = tweetLength - offset > limit
            ? limit
            : tweetLength - offset;
        Tweet[] memory result = new Tweet[](uint256(length));
        uint256 idx = 0;
        for (
            int256 i = length - offset - 1;
            length - offset - limit <= i;
            i--
        ) {
            if (
                i <= length - offset - 1 &&
                length - offset - limit <= i &&
                i >= 0
            ) {
                result[idx] = tweets[uint256(i)];
                idx++;
            }
        }
        return result;
    }

    function getUserTweets(address _address)
        public
        view
        virtual
        returns (Tweet[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < tweets.length; i++) {
            if (tweets[i].author == _address) {
                count++;
            }
        }

        Tweet[] memory result = new Tweet[](count);
        uint256 idx = 0;
        for (int256 i = int256(tweets.length - 1); 0 <= i; i--) {
            if (tweets[uint256(i)].author == _address) {
                result[idx] = tweets[uint256(i)];
                idx++;
            }
        }

        return result;
    }

    function follow(address _address) public virtual {
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

    function unfollow(address _address) public virtual {
        require(_address != msg.sender, "You cannot unfollow yourself.");

        for (uint256 i = 0; i < followings[msg.sender].length; i++) {
            if (followings[msg.sender][i].id == _address) {
                for (
                    uint256 j = i;
                    j < followings[msg.sender].length - 1;
                    j++
                ) {
                    followings[msg.sender][j] = followings[msg.sender][j + 1];
                }
                followings[msg.sender].pop();
            }
        }

        for (uint256 i = 0; i < followers[_address].length; i++) {
            if (followers[_address][i].id == msg.sender) {
                for (uint256 j = i; j < followers[_address].length - 1; j++) {
                    followers[_address][j] = followers[_address][j + 1];
                }
                followers[_address].pop();
            }
        }
    }

    function getFollowings(address _address)
        public
        view
        virtual
        returns (User[] memory)
    {
        return followings[_address];
    }

    function getFollowers(address _address)
        public
        view
        virtual
        returns (User[] memory)
    {
        return followers[_address];
    }

    function isFollowing(address _address) public view virtual returns (bool) {
        bool _following = false;
        for (uint256 i = 0; i < followings[msg.sender].length; i++) {
            if (followings[msg.sender][i].id == _address) {
                return true;
            }
        }
        return _following;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetaData(_tokenId);
    }

    function buildMetaData(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        Tweet memory tweet;
        for (uint256 i = 0; i < tweets.length; i++) {
            if (tweets[i].tokenId == _tokenId) {
                tweet = tweets[i];
            }
        }
        require(tweet.tokenId == _tokenId, "Tweet not found.");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Tweet #',
                                Strings.toString(_tokenId),
                                '", "description":"',
                                tweet.content,
                                '", "image": "',
                                TweetConstant.DEFAULT_IMAGE,
                                '", "image_data": "',
                                tweet.attachment,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
