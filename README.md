# Sealed Envelope Auction Smart Contract
This is a smart contract written in Solidity language that implements a Sealed Envelope Auction.

In a sealed envelope auction, bidders submit a bid in a sealed envelope without revealing the amount of their bid to others. After the bidding period is over, bidders reveal their bids, and the highest bidder wins the auction.

This smart contract has the following functionalities:

* Allows bidders to submit their sealed bids.
* Allows bidders to reveal their bids.
* Keeps track of the highest bid and the highest bidder.
* Allows bidders to withdraw their bids if they are not the highest bidder.
* Ends the auction and transfers the winning bid to the seller.
# Requirements
This smart contract is written in Solidity version 0.8.4.

# How to Use
To use this smart contract, deploy it on the Ethereum network using your preferred method (e.g., Remix IDE, Truffle, Hardhat, etc.).

Then, interact with the smart contract using the following functions:

sealBid(uint _value, string calldata _passcode) public view returns (bytes32): Takes the bid value and a passcode, and returns the hash of the sealed bid.
bid(bytes32 _sealedBid) external payable onlyBefore(endBiddingTime): Allows bidders to submit their sealed bid by providing the hash of their bid.
reveal(uint _value, string memory _passcode) external onlyAfter(endBiddingTime) onlyBefore(endRevealingTime): Allows bidders to reveal their bid by providing the bid value and the passcode. If the revealed bid is the highest, the bidder becomes the highest bidder. Otherwise, the bidder can withdraw their bid.
withdraw() public: Allows bidders to withdraw their bid if they are not the highest bidder.
endAuction() public payable onlyAfter(endRevealingTime): Ends the auction and transfers the winning bid to the seller.
# License
This smart contract is released under the MIT License.
