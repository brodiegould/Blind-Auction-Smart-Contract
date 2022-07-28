// A sealed-bid auction is a type of auction process in which all bidders simultaneously 
// submit sealed bids to the auctioneer so that no bidder knows how much the other auction 
// participants have bid. Sealed bid refers to a written bid placed in a sealed envelope. 
// The sealed bid is not opened until the stated date, at which time all bids are opened together. 
// The highest bidder is usually declared the winner of the bidding process.
// https://www.investopedia.com/terms/s/sealed-bid-auction.asp

// SPDX-License-Identifier: GPL-3.0

/** 
 * @title Sealed Bid Auction
 * @dev Allows bidders to silently bid on an auction, revealing highest bidder at auction end. locks funds temporarily
 */

///@authors - Brodie Gould

pragma solidity >= 0.7.0 <0.9.0;        //using compiler version 0.8.4
contract sealedEnvelopeAuction{


    // VARIABLES
    struct Bid {
        bytes32 sealedBid;
        uint depositAmt;
    }

    address payable public seller;                           //address that receives payment
    uint private endBid;                                     //tracks when time has ended
    uint private endReveal;                                  //tracks when the reveal period has ended
    bool private ended = false;                              //bool to track auction state
    uint private currentTime = block.timestamp;              //tracks current block time

    mapping(address => Bid[]) private bids;                   //bids map that holds an object of each accounts hashed bids

    address public highestBidder;
    uint public highestBid;

    mapping (address => uint) public toBeReturned;        //To allow withdrawals of unsuccessful bids.
    mapping (address => uint) private hasBidAlready;        //limit one bid per account
    // EVENTS
    event AuctionEnded(address winner, uint highestBid);    //reveals who won and what the highest bid was

    // MODIFIERS
    modifier onlyBefore(uint _time) { 
        require(block.timestamp < _time, "Too Late");
         _; 
    }
    modifier onlyAfter(uint _time) { 
        require(block.timestamp > _time, "Too Early");
         _; 
    }

    constructor(uint _biddingTime, uint _revealTime) {
        seller = payable(msg.sender);                                     //the person who initiates the smart contract is the auction seller
        endBid = block.timestamp + (_biddingTime * 1 minutes);            //duration of time the auction will stay live for
        endReveal = endBid + (_revealTime * 1 minutes);                   //duration of time we can see results after the auction ends
    }

    // FUNCTIONS
    function sealTheBid(uint _value, string memory _passcode) public view returns (bytes32) {
        //computes the hash of the bid with the value of the bid, and a bool specifying if the bid is real or not
        //in practice this would not be done on the blockchain, as the function parameters could be attacked by looking at the EVM nodes memory
        return keccak256(abi.encodePacked(_value,  _passcode, msg.sender));
    }

    function bid(bytes32 _sealedBid) external payable onlyBefore(endBid) {
        require(msg.sender != seller,"The host of the auction can't bid on their own auction");

        if(hasBidAlready[msg.sender] > 0){
            revert("There can only be one bid per account");
        }

        hasBidAlready[msg.sender] +=1;

        bids[msg.sender].push(Bid({                                
            sealedBid: _sealedBid,                  //sealedBid is the hash of the value and fake bool. 
            depositAmt: msg.value                   //refunds are only returned when the bidders bid value and bool match
        }));

        // bids={
        // [msg.sender : [[sealedBid 1 : H(value,passcode) , depositAmt: value]],
        // [msg.sender : [[sealedBid 2 : H(value,passcode) , depositAmt: value]],
        // [msg.sender : [.push(new bids)]                                   ]
        // }
    }

    function reveal(uint _values, string memory _passcode) external onlyAfter(endBid) onlyBefore(endReveal) {

            Bid storage usersBid = bids[msg.sender][0];   //create new Bid struct for the current bidders bid
            uint value = _values;
            string memory passcode = _passcode;

            require(usersBid.sealedBid == keccak256(abi.encodePacked(value, passcode, msg.sender)));

            //if the encoding is tied to this account
            if(usersBid.depositAmt >= value){             //if this is a valid bid (and you didn't lie about your transaction)
                if(!checkValue(msg.sender, value)) {          //if this is not a higher bid
                    payable(msg.sender).transfer(usersBid.depositAmt * (1 ether)); //allow user to withdraw this amount in withdrawels
                }
            }
            usersBid.sealedBid = bytes32(0);              //reset value of hash to zero to prevent someone from repeatedly returning funds
        }
    
    function checkValue(address _bidder, uint _value) internal returns(bool success) {      //only triggered within reveal function
        if (_value < highestBid){
            toBeReturned[payable(msg.sender)] = _value; // Put this line here to fix bug re: a bid trying to be revealed that is < than highestBid.
            return false;       //not a higher bid
        }

        //else this value is higher than the previous highest bid
        if (highestBidder != address(0)) {                  //if there has been at least one bid
            toBeReturned[highestBidder] = highestBid;    //move previous highest bid to the previous accounts toBeReturned
        }
        highestBid = _value;                                 //update bid winner to the current bid
        highestBidder = _bidder;
        return true;                                         //this was a higher bid
    }

    function withdraw() public {
        uint amount = toBeReturned[msg.sender];               //accesses the value that gets returned to the losing bidder
        if(amount > 0){                                 
            toBeReturned[msg.sender] = 0;                     //zero out balance before sending funds so withdraw can't be called repeatedly
            payable(msg.sender).transfer(amount * (1 ether));   //return funds to losing bidder
        }
    }

    function endAuction() public payable onlyAfter(endReveal) {
        require(!ended, "Auction hasn't ended yet");                           
        emit AuctionEnded(highestBidder, highestBid);          //execute event and declare the winner with the highest bid
        ended = true;                                          //prevent multiple payments being withdrawn
        seller.transfer(highestBid * (1 ether));               //send the highest bid to the seller
    }
}
