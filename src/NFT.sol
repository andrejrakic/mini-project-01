// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721URIStorage, ERC721} from "./vendor/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "./utils/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
  string constant TOKEN_URI = "https://ipfs.io/ipfs/QmYuKY45Aq87LeL1R5dhb1hqHLp6ZFbJaCP8jxqKM1MX6y/babe_ruth_1.json";
  uint256 internal s_nextTokenId;
  uint256 internal s_price;

  constructor(address owner, address pendingOwner, uint256 price) ERC721("MyNFT", "MNFT") Ownable(owner, pendingOwner) {
    s_price = price;
  }

  function mint(address to) external onlyOwner {
    // uint256 tokensRequired = price * decimals / priceFromOracle

    uint256 tokenId;
    unchecked {
      tokenId = s_nextTokenId++;
    }
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, TOKEN_URI);
  }
}
