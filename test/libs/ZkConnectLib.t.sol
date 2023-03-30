// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {HydraS2BaseTest} from "../verifiers/hydra-s2/HydraS2BaseTest.t.sol";
import {ZkConnect, RequestBuilder} from "src/libs/zk-connect/ZkConnectLib.sol";
import "src/libs/utils/Structs.sol";

contract ZkConnectLibTest is HydraS2BaseTest {
  ZkConnect zkConnect;
  ZkConnectRequest zkConnectRequest;
  bytes16 immutable appId = 0xf68985adfc209fafebfb1a956913e7fa;

  ZkConnectResponse validZkConnectResponse;

  function setUp() public virtual override {
    super.setUp();
    zkConnect = new ZkConnect(appId);

    Claim memory claimRequest = zkConnect.buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});

    address user = 0x7def1d6D28D6bDa49E69fa89aD75d160BEcBa3AE;

    zkConnectRequest = RequestBuilder.buildRequest({
      claimRequest: claimRequest,
      messageSignatureRequest: abi.encodePacked(user),
      appId: appId
    });

    validZkConnectResponse = hydraS2Proofs.getZkConnectResponse1();
  }

  // function test_RevertWith_InvalidZkConnectResponse() public {
  //   bytes memory zkConnectResponseEncoded = hex"";
  //   vm.expectRevert(abi.encodeWithSignature("ZkConnectResponseIsEmpty()"));
  //   zkConnect.verify(zkConnectResponseEncoded, zkConnectRequest);
  // }

  // function test_RevertWith_InvalidZkConnectVersion() public {
  //   ZkConnectResponse memory invalidZkConnectResponse = validZkConnectResponse;
  //   invalidZkConnectResponse.version = bytes32("fake-version");
  //   vm.expectRevert(
  //     abi.encodeWithSignature(
  //       "InvalidZkConnectVersion(bytes32,bytes32)",
  //       invalidZkConnectResponse.version,
  //       zkConnect.ZK_CONNECT_LIB_VERSION()
  //     )
  //   );
  //   zkConnect.verify(abi.encode(invalidZkConnectResponse), zkConnectRequest);
  // }

  // function test_RevertWith_InvalidZkConnectAppId() public {
  //   ZkConnectResponse memory invalidZkConnectResponse = validZkConnectResponse;
  //   invalidZkConnectResponse.appId = 0x00000000000000000000000000000f00;
  //   vm.expectRevert(
  //     abi.encodeWithSignature(
  //       "AppIdMismatch(bytes16,bytes16)",
  //       invalidZkConnectResponse.appId,
  //       validZkConnectResponse.appId
  //     )
  //   );
  //   zkConnect.verify(abi.encode(invalidZkConnectResponse), zkConnectRequest);
  // }

  // function test_RevertWith_InvalidNamespace() public {
  //   ZkConnectResponse memory invalidZkConnectResponse = validZkConnectResponse;
  //   invalidZkConnectResponse.namespace = bytes16(keccak256("fake-namespace"));
  //   vm.expectRevert(
  //     abi.encodeWithSignature(
  //       "NamespaceMismatch(bytes16,bytes16)",
  //       invalidZkConnectResponse.namespace,
  //       validZkConnectResponse.namespace
  //     )
  //   );
  //   zkConnect.verify(abi.encode(invalidZkConnectResponse), zkConnectRequest);
  // }

  // function test_RevertWith_UnequalProofsAndStatementRequestsLength() public {
  //   ZkConnectResponse memory invalidZkConnectResponse = validZkConnectResponse;
  //   invalidZkConnectResponse.proofs = new ZkConnectProof[](0);
  //   vm.expectRevert(
  //     abi.encodeWithSignature(
  //       "ProofsAndDataRequestsAreUnequalInLength(uint256,uint256)",
  //       invalidZkConnectResponse.proofs.length,
  //       zkConnectRequest.content.dataRequests.length
  //     )
  //   );
  //   zkConnect.verify(abi.encode(invalidZkConnectResponse), zkConnectRequest);
  // }

  function test_ZkConnectLibWithOnlyClaim() public {
    bytes
      memory zkResponseEncoded = hex"0000000000000000000000000000000000000000000000000000000000000020f68985adfc209fafebfb1a956913e7fa00000000000000000000000000000000b8e2054f8a912367e38a22ce773328ff000000000000000000000000000000007a6b2d636f6e6e6563742d76320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000022068796472612d73322e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000540e9ed316946d3d98dfcd829a53ec9822e000000000000000000000000000000006c617465737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007def1d6d28d6bda49e69fa89ad75d160becba3ae00000000000000000000000000000000000000000000000000000000000002c0220ec2678460ece47a0a7d64eb05529881d9056f89965157de6043b913fa1ac817984c470e3c6c06146d7adbc299fc7e7b1828813afe1b91986f1219c5c424332ec6e6957db805a319019526e7bc7ca34b3c069f153b2f6f7ede5bb42a2181ac159a93759a5eb820ebaa8b0aa1bc3da1e3ca3b79701f13c723741d78a80c48d403867770c85a774446e110f39ef9154f9c79aa98d4ddb499f31fd643393498992d84dbedbfe25599fc7c8a8ca74f79e251eab78eb803cf2d4792587b560ac71111e5eb59ebf229fdad2d142d0929dc6add9e5e110fc2b6da0b25d3eb2a14b031293e68a737ad08e26f526ec522504300995058df6d3c8c4644500f006b66807e000000000000000000000000000000000000000000000000000000000000000009f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d07f6c5612eb579788478789deccb06cf0eb168e457eea490af754922939ebdb920706798455f90ed993f8dac8075fc1538738a25f0c928da905c0dffd81869fa2db629f18dc904ef403dd497303d02e8f0b4059786899373d734f3c6389442ec0edcebd3d30d0a9e5ba1fbaae8057165de46b61ddc5e81b1701dbf79995d77e51f853dbff160e80ee19ed2e3ae534c228873736d841ecec2339564c28a31db2d0000000000000000000000000000000000000000000000000000000000000001285bf79dc20d58e71b9712cb38c420b9cb91d3438c8e3dbaf07829b03ffffffc000000000000000000000000000000000000000000000000000000000000000015fb9d7ca9f692b09201b5277a41f295ce6530786b4ce23051ef72c53252097300000000000000000000000000000000f68985adfc209fafebfb1a956913e7fa000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    //bytes memory zkResponseEncoded = abi.encode(hydraS2Proofs.getZkConnectResponse1());

    ZkConnectVerifiedResult memory zkConnectVerifiedResult = zkConnect.verify(
      zkResponseEncoded,
      zkConnectRequest
    );
    assertEq(zkConnectVerifiedResult.verifiedAuths[0].userId, 0);
  }

  function test_ZkConnectLibWithOnlyOneAuth() public {
    bytes
      memory zkResponseEncoded = hex"0000000000000000000000000000000000000000000000000000000000000020f68985adfc209fafebfb1a956913e7fa00000000000000000000000000000000b8e2054f8a912367e38a22ce773328ff000000000000000000000000000000007a6b2d636f6e6e6563742d76320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000022068796472612d73322e31000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000260000000000000000000000000000000000000000000000000000000000000054000000000000000000000000000000000000000000000000000000000000000006c617465737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007def1d6d28d6bda49e69fa89ad75d160becba3ae00000000000000000000000000000000000000000000000000000000000002c006f1a47b6a3490b2b123a5181a8a8e0adc82ab9d0a8e0360538548be602e05d7293f98e1de1b22a392bcc8505bbbadae1b302637e70c285d0aebc904221519a827892671bde30524208a8d76eb2c492f41bfe786583938e8452ba2d61a3df38f2cff567bfca46c95ce50e9e826a99adca948c83fa160f40b87b00bb5f93bd1340e0efaed25aa2036c7d75f1c0ae84fd58c1c4a86fe0a043844ece68ada0f013a227b0c1bb810ef1810fa0ffa50eb5e5c4a8deb9e52dcb45790ddb3d70f778c4f1d2ac59920be4cfc3854b4adb7ea4d80691d544f174585843da4344d929e156612913a7502defcadaccf0c6c18aa0db183d5346bf9f94ab4f9b03d47873710f8000000000000000000000000000000000000000000000000000000000000000009f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d07f6c5612eb579788478789deccb06cf0eb168e457eea490af754922939ebdb920706798455f90ed993f8dac8075fc1538738a25f0c928da905c0dffd81869fa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021bbc0d6dbcf41f639e1e31aa0ff518cf81e3ddd92db142e8c4f3370a36c1a7000000000000000000000000000000000f68985adfc209fafebfb1a956913e7fa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    Auth memory authRequest = zkConnect.buildAuth({authType: AuthType.ANON});
    address user = 0x7def1d6D28D6bDa49E69fa89aD75d160BEcBa3AE;
    zkConnectRequest = RequestBuilder.buildRequest({
      authRequest: authRequest,
      messageSignatureRequest: abi.encodePacked(user),
      appId: appId
    });

    ZkConnectVerifiedResult memory zkConnectVerifiedResult = zkConnect.verify(
      zkResponseEncoded,
      zkConnectRequest
    );
    assertTrue(zkConnectVerifiedResult.verifiedAuths[0].userId != 0);
  }

  function test_ZkConnectLibWithClaimAndAuth() public {
    bytes
      memory zkResponseEncoded = hex"0000000000000000000000000000000000000000000000000000000000000020f68985adfc209fafebfb1a956913e7fa00000000000000000000000000000000b8e2054f8a912367e38a22ce773328ff000000000000000000000000000000007a6b2d636f6e6e6563742d76320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000022068796472612d73322e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002600000000000000000000000000000000000000000000000000000000000000540e9ed316946d3d98dfcd829a53ec9822e000000000000000000000000000000006c617465737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007def1d6d28d6bda49e69fa89ad75d160becba3ae00000000000000000000000000000000000000000000000000000000000002c0049684b3c3d4644fb69c760d491a24176bbf5778861f0660d8b1e65f1b2e54530de941d273b3dfad8cd2d3b656f4011a8552c8210c28c5aa15615abc4faf7ff003f5cb81e05925f4ad1b89a811ff4ee6d0230bfd880fb11f1dd110aad36438a929f1f418260bdddbe8f3e02526ab15c89b6b733efffd00efa9ae6395f009f09b0d66c42462ed49e62b8e8398f1cf0844fd32c7e715c887555fe2cf81c3bac3ac176940ff350e0f18a55c7c5713486a400e4df1651406f757221cf15b0f09ebd6179b0d5b2ad3de7b59518d74aea929ecf7c48911f3a4d5a871e462c60459866c11d0e94706f5d9a4407955641aed778eafcc75902d7653b3fa04a5a9d5205a4e000000000000000000000000000000000000000000000000000000000000000009f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d07f6c5612eb579788478789deccb06cf0eb168e457eea490af754922939ebdb920706798455f90ed993f8dac8075fc1538738a25f0c928da905c0dffd81869fa2db629f18dc904ef403dd497303d02e8f0b4059786899373d734f3c6389442ec0edcebd3d30d0a9e5ba1fbaae8057165de46b61ddc5e81b1701dbf79995d77e51f853dbff160e80ee19ed2e3ae534c228873736d841ecec2339564c28a31db2d0000000000000000000000000000000000000000000000000000000000000001285bf79dc20d58e71b9712cb38c420b9cb91d3438c8e3dbaf07829b03ffffffc000000000000000000000000000000000000000000000000000000000000000015fb9d7ca9f692b09201b5277a41f295ce6530786b4ce23051ef72c53252097300000000000000000000000000000000f68985adfc209fafebfb1a956913e7fa000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    // bytes memory zkResponseEncoded = abi.encode(hydraS2Proofs.getZkConnectResponse1());

    Claim memory claimRequest = zkConnect.buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    Auth memory authRequest = zkConnect.buildAuth({authType: AuthType.ANON});
    address user = 0x7def1d6D28D6bDa49E69fa89aD75d160BEcBa3AE;
    zkConnectRequest = RequestBuilder.buildRequest({
      claimRequest: claimRequest,
      authRequest: authRequest,
      messageSignatureRequest: abi.encodePacked(user),
      appId: appId
    });

    ZkConnectVerifiedResult memory zkConnectVerifiedResult = zkConnect.verify(
      zkResponseEncoded,
      zkConnectRequest
    );
    assertTrue(zkConnectVerifiedResult.verifiedAuths[0].userId != 0);
  }

  // function test_ZkConnectLibTwoDataRequests() public {
  //     Claim memory claimRequest = ClaimRequestLib.build({
  //         groupId: 0xe9ed316946d3d98dfcd829a53ec9822e,
  //         groupTimestamp: bytes16("latest"),
  //         value: 2,
  //         claimType: ClaimType.EQ
  //     });

  //     Auth memory authRequest = AuthRequestLib.build({authType: AuthType.EVM_ACCOUNT, anonMode: true});

  //     Claim memory claimRequestTwo =
  //         ClaimRequestLib.build({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e, value: 1, claimType: ClaimType.GTE});

  //     Auth memory authRequestTwo = AuthRequestLib.build({authType: AuthType.ANON});

  //     DataRequest[] memory dataRequests = new DataRequest[](2);
  //     dataRequests[0] = DataRequestLib.build({claimRequest: claimRequest, authRequest: authRequest});
  //     dataRequests[1] = DataRequestLib.build({claimRequest: claimRequestTwo, authRequest: authRequestTwo});

  //     zkConnectRequestContent = ZkConnectRequestContentLib.build({dataRequests: dataRequests});

  //     bytes memory zkResponseEncoded = abi.encode(hydraS2Proofs.getZkConnectResponse1());

  //     ZkConnectVerifiedResult memory zkConnectVerifiedResult =
  //         zkConnect.verify(zkResponseEncoded, zkConnectRequestContent);
  //     console.log("userId: %s", zkConnectVerifiedResult.verifiedAuths[0].userId);
  // }
}
