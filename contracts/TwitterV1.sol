//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./Base64.sol";
import "./TweetValidation.sol";
import "./TweetConstant.sol";

contract TwitterV1 is Initializable, ERC721EnumerableUpgradeable {
    using Strings for uint256;
    using TweetValidation for string;
    using Base64 for bytes;

    struct User {
        address id;
        string iconUrl;
    }

    struct Tweet {
        uint256 tokenId;
        string content;
        address author;
        uint256 timestamp;
        string attachment;
        address[] likes; // want to use User[] but not supported yet.
        address[] retweets;
        string iconUrl;
    }

    // For global access
    Tweet[] public tweets;
    mapping(address => User) public users;

    // For specifil tweet
    mapping(uint256 => Tweet[]) public comments;

    // For specific users
    mapping(address => User[]) public followings;
    mapping(address => User[]) public followers;
    mapping(address => Tweet[]) public likes;

    event Tweeted(address indexed sender, string tweet);
    event Commented(address indexed sender, string tweet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC721_init("TwitterETH", "TWTE");
    }

    function initialize() public initializer {}

    // Set tweet to storage and mint it as NFT. Text tweets and image tweets are supported. Tweet can not be deleted by anyone.
    function setTweet(string memory _tweet, string memory _imageData) public virtual {
        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        string memory iconUrl;
        if (users[msg.sender].iconUrl.notEmpty()) {
            iconUrl = users[msg.sender].iconUrl;
        }

        Tweet memory tweet;
        if (_imageData.notEmpty()) {
            tweet.tokenId = tokenId;
            tweet.content = _tweet;
            tweet.author = msg.sender;
            tweet.timestamp = block.timestamp;
            tweet.attachment = _imageData;
            tweet.iconUrl = iconUrl;
            tweets.push(tweet);
            _safeMint(msg.sender, supply + 1);
        } else {
            require(_tweet.notEmpty(), "TooShort");
            require(_tweet.noSpace(), "NoSpace");
            tweet.tokenId = tokenId;
            tweet.content = _tweet;
            tweet.author = msg.sender;
            tweet.timestamp = block.timestamp;
            tweet.iconUrl = iconUrl;
            tweets.push(tweet);
            _safeMint(msg.sender, supply + 1);
        }

        emit Tweeted(msg.sender, _tweet);
    }

    function getTimeline(int256 offset, int256 limit) public view virtual returns (Tweet[] memory) {
        require(offset >= 0);

        if (uint256(offset) > tweets.length) {
            return new Tweet[](0);
        }

        int256 tweetLength = int256(tweets.length);
        int256 length = tweetLength - offset > limit ? limit : tweetLength - offset;
        Tweet[] memory result = new Tweet[](uint256(length));
        uint256 idx = 0;
        for (int256 i = length - offset - 1; length - offset - limit <= i; i--) {
            if (i <= length - offset - 1 && length - offset - limit <= i && i >= 0) {
                result[idx] = tweets[uint256(i)];
                idx++;
            }
        }
        return result;
    }

    function getUserTweets(address _address) public view virtual returns (Tweet[] memory) {
        if (tweets.length == 0) {
            return new Tweet[](0);
        }

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

    function getTweet(uint256 _tokenId) public view virtual returns (Tweet memory) {
        Tweet memory result;
        if (tweets.length == 0) {
            return result;
        }
        for (uint256 i = 0; i < tweets.length; i++) {
            if (tweets[i].tokenId == _tokenId) {
                result = tweets[i];
                break;
            }
        }
        return result;
    }

    function follow(address _address) public virtual {
        require(_address != msg.sender);

        string memory myIconUrl;
        string memory otherIconUrl;
        if (users[msg.sender].iconUrl.notEmpty()) {
            myIconUrl = users[msg.sender].iconUrl;
        }
        if (users[_address].iconUrl.notEmpty()) {
            otherIconUrl = users[_address].iconUrl;
        }

        bool exists = false;
        for (uint256 i = 0; i < followings[msg.sender].length; i++) {
            if (followings[msg.sender][i].id == _address) {
                exists = true;
            }
        }
        if (!exists) {
            followings[msg.sender].push(User({id: _address, iconUrl: otherIconUrl}));
        }

        exists = false;
        for (uint256 i = 0; i < followers[_address].length; i++) {
            if (followers[_address][i].id == msg.sender) {
                exists = true;
            }
        }
        if (!exists) {
            followers[_address].push(User({id: msg.sender, iconUrl: myIconUrl}));
        }
    }

    function unfollow(address _address) public virtual {
        require(_address != msg.sender);

        for (uint256 i = 0; i < followings[msg.sender].length; i++) {
            if (followings[msg.sender][i].id == _address) {
                for (uint256 j = i; j < followings[msg.sender].length - 1; j++) {
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

    function getFollowings(address _address) public view virtual returns (User[] memory) {
        return followings[_address];
    }

    function getFollowers(address _address) public view virtual returns (User[] memory) {
        return followers[_address];
    }

    function isFollowing(address _address) public view virtual returns (bool) {
        bool _following = false;
        for (uint256 i = 0; i < followings[msg.sender].length; i++) {
            if (followings[msg.sender][i].id == _address) {
                _following = true;
                break;
            }
        }
        return _following;
    }

    // Like is kept forever. can not be removed.
    function addLike(uint256 _tokenId) public virtual {
        // Avoid duplicate likes.
        for (uint256 i = 0; i < likes[msg.sender].length; i++) {
            if (likes[msg.sender][i].tokenId == _tokenId) {
                return;
            }
        }

        for (uint256 i = 0; i < tweets.length; i++) {
            if (tweets[i].tokenId == _tokenId) {
                tweets[i].likes.push(msg.sender);
                likes[msg.sender].push(tweets[i]);
            }
        }
    }

    // Get my like's tweets.
    function getLikes(address _address) public view virtual returns (Tweet[] memory) {
        return likes[_address];
    }

    // Retweet is kept forever. can not be removed.
    // It's possible to retweet many times.
    function addRetweet(uint256 _tokenId) public virtual {
        Tweet memory latestTweet;
        for (uint256 i = 0; i < tweets.length; i++) {
            // original tweet only.
            if (tweets[i].tokenId == _tokenId) {
                tweets[i].retweets.push(msg.sender);
                latestTweet = tweets[i];
            }
        }
        tweets.push(latestTweet);
    }

    // Get icon.
    function getUserIcon(address _address) public view virtual returns (string memory) {
        return users[_address].iconUrl;
    }

    // Change iconUrl of user.
    // Anyone can set up any iconUrl which is not own NFT...
    function changeIconUrl(string memory _url) public virtual {
        users[msg.sender].id = msg.sender;
        users[msg.sender].iconUrl = _url;
    }

    // Add comment to specific tweet.
    function setComment(string memory _comment, uint256 _tokenId) public virtual {
        uint256 supply = totalSupply();
        require(_tokenId <= supply, "InvalidId");

        string memory iconUrl;
        if (users[msg.sender].iconUrl.notEmpty()) {
            iconUrl = users[msg.sender].iconUrl;
        }

        Tweet memory comment;
        require(_comment.notEmpty(), "TooShort");
        require(_comment.noSpace(), "NoSpace");
        comment.tokenId = _tokenId;
        comment.content = _comment;
        comment.author = msg.sender;
        comment.timestamp = block.timestamp;
        comment.iconUrl = iconUrl;
        comments[_tokenId].push(comment);

        emit Commented(msg.sender, _comment);
    }

    // Get comments of specific tweet.
    function getComments(uint256 _tokenId) public view virtual returns (Tweet[] memory) {
        return comments[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId));
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
                    bytes(
                        abi.encodePacked(
                            '{"name":"Tweet #',
                            _tokenId.toString(),
                            '", "description":"',
                            tweet.content,
                            '", "image": "',
                            TweetConstant.DEFAULT_IMAGE,
                            '", "image_data": "',
                            tweet.attachment,
                            '"}'
                        )
                    ).encode()
                )
            );
    }
}
