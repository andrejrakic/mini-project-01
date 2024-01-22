// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721URIStorage, ERC721} from "./vendor/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "./utils/Ownable.sol";
import {AggregatorV3Interface} from "./vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "./vendor/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "./vendor/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFT is ERC721URIStorage, Ownable {
  using SafeERC20 for IERC20;

  struct StableTokenDetails {
    address chainlinkAggregatorAddress; // ─╮
    uint32 stalePriceDuration; //           │
    uint8 tokenDecimals; // ────────────────╯
  }

  string constant TOKEN_URI = "https://ipfs.io/ipfs/QmYuKY45Aq87LeL1R5dhb1hqHLp6ZFbJaCP8jxqKM1MX6y/babe_ruth_1.json";
  uint256 internal s_nextTokenId;
  uint256 internal s_priceInUsd;

  mapping(address stableTokenAddress => StableTokenDetails details) internal s_stableTokenDetails;

  event StableTokenEnabled(
    address indexed tokenAddress,
    address chainlinkAggregatorAddress,
    uint32 stalePriceDuration,
    uint8 tokenDecimals
  );
  event StableTokenDisabled(address indexed tokenAddress);

  error NFT__UnsupportedPaymentToken(address tokenAddress);
  error NFT__StalePrice(
    address tokenAddress,
    uint256 lastPriceUpdateTimestamp,
    uint256 currentTimestamp,
    uint32 stalePriceDuration
  );
  error NFT__Depeg(int256 reportedPrice);

  constructor(address owner, address pendingOwner, uint256 price) ERC721("MyNFT", "MNFT") Ownable(owner, pendingOwner) {
    s_priceInUsd = price;
  }

  function enableStableToken(
    address _tokenAddress,
    address _chainlinkAggregatorAddress,
    uint32 _stalePriceDuration,
    uint8 _tokenDecimals
  ) external onlyOwner {
    s_stableTokenDetails[_tokenAddress] = StableTokenDetails({
      chainlinkAggregatorAddress: _chainlinkAggregatorAddress,
      stalePriceDuration: _stalePriceDuration,
      tokenDecimals: _tokenDecimals
    });

    emit StableTokenEnabled(_tokenAddress, _chainlinkAggregatorAddress, _stalePriceDuration, _tokenDecimals);
  }

  function disableStableToken(address _tokenAddress) external onlyOwner {
    delete s_stableTokenDetails[_tokenAddress];

    emit StableTokenDisabled(_tokenAddress);
  }

  function mint(address _to, address _paymentTokenAddress) external /*nonReentrant*/ {
    StableTokenDetails memory stableTokenDetails = s_stableTokenDetails[_paymentTokenAddress];

    if (stableTokenDetails.chainlinkAggregatorAddress == address(0))
      revert NFT__UnsupportedPaymentToken(_paymentTokenAddress);

    AggregatorV3Interface priceFeed = AggregatorV3Interface(stableTokenDetails.chainlinkAggregatorAddress);

    (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();

    if (updatedAt < block.timestamp - stableTokenDetails.stalePriceDuration) {
      revert NFT__StalePrice(_paymentTokenAddress, updatedAt, block.timestamp, stableTokenDetails.stalePriceDuration);
    }

    // @TODO: Consider handling potential stable coins depeges

    uint256 tokensRequired;
    unchecked {
      tokensRequired =
        (s_priceInUsd * uint256(price) * 10 ** stableTokenDetails.tokenDecimals) /
        10 ** priceFeed.decimals();
    }

    IERC20(_paymentTokenAddress).safeTransferFrom(msg.sender, address(this), tokensRequired);

    uint256 tokenId;
    unchecked {
      tokenId = s_nextTokenId++;
    }

    _safeMint(_to, tokenId);
    _setTokenURI(tokenId, TOKEN_URI);
  }

  function isStableTokenSupported(address _tokenAddress) public view returns (bool) {
    return s_stableTokenDetails[_tokenAddress].chainlinkAggregatorAddress == address(0);
  }

  function withdraw(address _to, address _tokenAddress, uint256 _amount) external onlyOwner /*nonReentrant*/ {
    IERC20(_tokenAddress).safeTransfer(_to, _amount);
  }
}
