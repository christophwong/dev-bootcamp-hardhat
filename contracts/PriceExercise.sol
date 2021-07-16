pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract PriceExercise is ChainlinkClient {
  bool public priceFeedGreater;
  int256 public storedPrice;


  address private oracle;
  bytes32 private jobId;
  uint256 private fee;
  AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Oracle: 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Job ID: 29fa9aa13bf1468788b7cc4a500a45b8
     * Fee: 0.1 LINK

     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
  constructor(address _oracle, string memory _jobId, uint256 _fee, address _link, address _priceFeed) public {
      priceFeed = AggregatorV3Interface(_priceFeed);

      if (_link == address(0)) {
          setPublicChainlinkToken();
      } else {
          setChainlinkToken(_link);
      }
      // oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
      // jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
      // fee = 0.1 * 10 ** 18; // 0.1 LINK
      oracle = _oracle;
      jobId = stringToBytes32(_jobId);
      fee = _fee;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function requestPriceData() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the get URL to BTC-USD price data api.
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD");

        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"BTC":
        //    {"USD":
        //     {
        //      "PRICE": xxxxx.xx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "RAW.BTC.USD.PRICE");

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, int256 _price) public recordChainlinkFulfillment(_requestId) {
        storedPrice = _price;

        if (getLatestPrice() > storedPrice){
          priceFeedGreater = true;
        } else {
          priceFeedGreater = false;
        }

    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

     /**
     * For development only; DO NOT USE IN PRODUCTION
     * Withdraw LINK from this contract
     *
     */
    function withdrawLink() external {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        require(linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))), "Unable to transfer");
    }

}