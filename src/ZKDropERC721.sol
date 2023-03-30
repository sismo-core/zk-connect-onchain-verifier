// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./libs/zk-connect/ZkConnectLib.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ZKDropERC721 is ERC721, ZkConnect {
  bytes16 public immutable GROUP_ID;
  ZkConnectRequestContent private zkConnectRequestContent;

  string private _baseTokenURI;

  event BaseTokenURIChanged(string baseTokenURI);

  constructor(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    bytes16 appId,
    bytes16 groupId
  ) ERC721(name, symbol) ZkConnect(appId) {
    GROUP_ID = groupId;
    _setBaseTokenURI(baseTokenURI);
  }

  function claimWithZkConnect(bytes memory zkConnectResponse) public {
    ZkConnectVerifiedResult memory zkConnectVerifiedResult = verify(
      zkConnectResponse,
      buildAuth({authType: AuthType.ANON}),
      buildClaim({groupId: GROUP_ID})
    );

    ZkConnectVerifiedResult memory zkConnectVerifiedResult1 = verify(
      zkConnectResponse,
      buildAuth({authType: AuthType.ANON})
    );

    ZkConnectVerifiedResult memory zkConnectVerifiedResult2 = verify(
      zkConnectResponse,
      buildClaim({groupId: GROUP_ID})
    );

    address to = abi.decode(zkConnectVerifiedResult.signedMessages[0], (address));
    uint256 tokenId = zkConnectVerifiedResult.verifiedAuths[0].userId;
    _mint(to, tokenId);
  }

  function transferWithZkConnect(bytes memory zkConnectResponse) public {
    // ZkConnectVerifiedResult memory zkConnectVerifiedResult = verify(
    //   zkConnectResponse,
    //   zkConnectRequestContent
    // );
    // address to = abi.decode(zkConnectVerifiedResult.signedMessages[0], (address));
    // uint256 tokenId = zkConnectVerifiedResult.verifiedAuths[0].userId;
    // address from = ownerOf(tokenId);
    // _transfer(from, to, tokenId);
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _setBaseTokenURI(string memory baseURI) private {
    _baseTokenURI = baseURI;
    emit BaseTokenURIChanged(baseURI);
  }
}