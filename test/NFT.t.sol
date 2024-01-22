// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {NFT, Ownable} from "../src/NFT.sol";

contract NFTTest is Test {
  NFT public nft;
  uint256 mintingPriceInUsd;
  address owner;
  address alice;

  function setUp() public {
    mintingPriceInUsd = 5;
    owner = makeAddr("owner");
    alice = makeAddr("alice");

    nft = new NFT(owner, address(0), mintingPriceInUsd);
    // https://book.getfoundry.sh/cheatcodes/mock-call?highlight=mock#description
  }

  function test_SetPrice() external {
    vm.startPrank(owner);
    assertEq(nft.getMintingPrice(), mintingPriceInUsd);
    uint256 newPrice = 10;
    nft.setMintingPrice(newPrice);
    assertEq(nft.getMintingPrice(), newPrice);
    vm.stopPrank();
  }

  function test_RevertIf_CallerIsNotAnOwner() external {
    uint256 newPrice = 10;
    vm.expectRevert(abi.encodeWithSelector(Ownable.Ownable__CallerIsNotOwner.selector));
    nft.setMintingPrice(newPrice);
  }
}
