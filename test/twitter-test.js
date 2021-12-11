const { expect } = require("chai");
const { assert } = require("console");
const { ethers } = require("hardhat");

describe("Twitter", function () {
  it("Should return error", async function () {
    const [owner] = await ethers.getSigners();
    const Twitter = await ethers.getContractFactory("TwitterV1");
    const twitter = await Twitter.deploy();
    await twitter.deployed();
    await expect(twitter.setTweet("     ")).to.be.reverted;
  });

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
