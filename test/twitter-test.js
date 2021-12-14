const { expect } = require("chai");
const { assert } = require("console");
const { ethers } = require("hardhat");

describe("Twitter", function () {
  describe("setTweet", function () {
    it("Should return error", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();
      await expect(twitter.setTweet("     ")).to.be.reverted;
    });
  });

  describe("getTimeline", function () {
    it("Should return the tweet", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      const tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();
      const tweets = await twitter.getTimeline(0, 10);
      const tweet = tweets[0];
      expect(tweet.content).to.equal("Hello, world!");
      expect(tweet.author).to.equal(owner.address);
    });
  });

  describe("getUserTweets", function () {
    it("Should return the tweet", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();
      tx = await twitter.setTweet("Hello, new world!", "");
      await tx.wait();

      const tweets = await twitter.getUserTweets(owner.address);
      const tweet = tweets[0];
      expect(tweet.content).to.equal("Hello, new world!");
      expect(tweet.author).to.equal(owner.address);
    });

    it("Should return the tweet", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet(
        "Hello, world!",
        "data:image/png;base64,XXXX"
      );
      await tx.wait();

      const tweets = await twitter.getUserTweets(owner.address);
      const tweet = tweets[0];
      expect(tweet.content).to.equal("Hello, world!");
      expect(tweet.author).to.equal(owner.address);
      expect(tweet.attachment).to.equal("data:image/png;base64,XXXX");
    });
  });

  describe("getTweet", function () {
    it("Should return the tweet", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();

      const tweet = await twitter.getTweet(1);
      expect(tweet.content).to.equal("Hello, world!");
      expect(tweet.author).to.equal(owner.address);
    });
  });

  describe("follow", function () {
    it("Should follow user", async function () {
      const [owner, user] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.follow(user.address);
      await tx.wait();

      const followings = await twitter.getFollowings(owner.address);
      const following = followings[0];
      expect(following.id).to.equal(user.address);

      const followers = await twitter.getFollowers(user.address);
      const follower = followers[0];
      expect(follower.id).to.equal(owner.address);
    });
  });

  describe("getFollowings", function () {
    it("Should unfollow user", async function () {
      const [owner, user, user2] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.follow(user.address);
      await tx.wait();
      tx = await twitter.follow(user2.address);
      await tx.wait();

      let followings = await twitter.getFollowings(owner.address);
      expect(followings.length).to.equal(2);
      let followers = await twitter.getFollowers(user.address);
      expect(followers.length).to.equal(1);
      followers = await twitter.getFollowers(user2.address);
      expect(followers.length).to.equal(1);

      tx = await twitter.unfollow(user.address);
      await tx.wait();
      followings = await twitter.getFollowings(owner.address);
      expect(followings.length).to.equal(1);
      followers = await twitter.getFollowers(user.address);
      expect(followers.length).to.equal(0);
      followers = await twitter.getFollowers(user2.address);
      expect(followers.length).to.equal(1);
    });
  });

  describe("isFollowing", function () {
    it("Should true if follow the address", async function () {
      const [owner, user] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.follow(user.address);
      await tx.wait();

      const following = await twitter.isFollowing(user.address);
      expect(following).to.equal(true);
    });
  });

  describe("addLike", function () {
    it("Should add a like to the tweet", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();

      let tweets = await twitter.getUserTweets(owner.address);
      let tweet = tweets[0];
      expect(tweet.likes.includes(owner.address)).to.be.false;

      tx = await twitter.addLike(tweet.tokenId);
      await tx.wait();
      tweets = await twitter.getUserTweets(owner.address);
      tweet = tweets[0];
      expect(tweet.likes.includes(owner.address)).to.be.true;
    });
  });

  describe("getLikes", function () {
    it("Should return liked tweets", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();

      let tweets = await twitter.getLikes(owner.address);
      expect(tweets.length).to.equal(0);

      tweets = await twitter.getUserTweets(owner.address);
      let tweet = tweets[0];

      tx = await twitter.addLike(tweet.tokenId);
      await tx.wait();

      tweets = await twitter.getLikes(owner.address);
      tweet = tweets[0];
      expect(tweet.likes.includes(owner.address)).to.be.true;
    });
  });

  describe("changeIconUrl/getUserIcon", function () {
    it("Should change icon url", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let url = await twitter.getUserIcon(owner.address);
      expect(url).to.equal("");

      let tx = await twitter.changeIconUrl("https://example.com/icon.png");
      await tx.wait();

      url = await twitter.getUserIcon(owner.address);
      expect(url).to.equal("https://example.com/icon.png");
    });
  });

  describe("setComment/getComments", function () {
    it("Should add the comment", async function () {
      const [owner] = await ethers.getSigners();
      const Twitter = await ethers.getContractFactory("TwitterV1");
      const twitter = await Twitter.deploy();
      await twitter.deployed();

      let tx = await twitter.setTweet("Hello, world!", "");
      await tx.wait();

      tx = await twitter.setComment("Hello, comment!", 1);
      await tx.wait();

      const comments = await twitter.getComments(1);
      const comment = comments[0];
      expect(comment.content).to.equal("Hello, comment!");
      expect(comment.author).to.equal(owner.address);
    });
  });
});
