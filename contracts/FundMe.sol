// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    //create a mapping to track the address and money
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //constructor: constructor function will be executed immediately after deploying contract
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //track the transactions
    function fund() public payable {
        //the minimum USD
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Don't meet the 50$'s minimum value"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    /**
     * Network:Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     *
     */
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    //return the lastest price of eth by usd
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    //3142,27520082

    //get convert from eth to USD
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    //modifier: used to change the behavior of a function in a declarative way
    //meet the require first, before run next function
    //Before we run the _;(which is the withdraw function), check the modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //withdraw the money by owner
    function withdraw() public payable onlyOwner {
        //transfer: send ETH from one address to another address
        //send eth to msg.sender
        //this: the contract you are current in
        msg.sender.transfer(address(this).balance);
        //update the funders' balance = 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset our funder array
        funders = new address[](0);
    }
}
