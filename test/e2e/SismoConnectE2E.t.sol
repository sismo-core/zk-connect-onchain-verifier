// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "src/libs/utils/Fmt.sol";
import {HydraS3BaseTest} from "../verifiers/hydra-s3/HydraS3BaseTest.t.sol";
import {SismoConnect, RequestBuilder, ClaimRequestBuilder, SismoConnectConfigBuilder} from "src/libs/sismo-connect/SismoConnectLib.sol";
import {ZKDropERC721} from "src/ZKDropERC721.sol";
import "src/libs/utils/Structs.sol";
import {SismoConnectHarness} from "test/harness/SismoConnectHarness.sol";

import {AuthBuilder} from "src/libs/utils/AuthBuilder.sol";
import {ClaimBuilder} from "src/libs/utils/ClaimBuilder.sol";
import {ResponseBuilder, ResponseWithoutProofs} from "test/utils/ResponseBuilderLib.sol";
import {BaseDeploymentConfig} from "script/BaseConfig.sol";

// E2E tests for SismoConnect Solidity Library
// These tests are made with proofs generated from the Vault App
// These tests should not use any Verifier mocks

contract SismoConnectE2E is HydraS3BaseTest {
  using ResponseBuilder for SismoConnectResponse;
  using ResponseBuilder for ResponseWithoutProofs;

  SismoConnectHarness sismoConnect;
  address user = 0x7def1d6D28D6bDa49E69fa89aD75d160BEcBa3AE;

  // default values for tests
  bytes16 public DEFAULT_APP_ID = 0x11b1de449c6c4adb0b5775b3868b28b3;
  bytes16 public DEFAULT_NAMESPACE = bytes16(keccak256("main"));
  bytes32 public DEFAULT_VERSION = bytes32("sismo-connect-v1.1");
  bytes public DEFAULT_SIGNED_MESSAGE = abi.encode(user);

  bool public DEFAULT_IS_IMPERSONATION_MODE = false;

  ResponseWithoutProofs public DEFAULT_RESPONSE =
    ResponseBuilder
      .emptyResponseWithoutProofs()
      .withAppId(DEFAULT_APP_ID)
      .withVersion(DEFAULT_VERSION)
      .withNamespace(DEFAULT_NAMESPACE)
      .withSignedMessage(DEFAULT_SIGNED_MESSAGE);

  ClaimRequest claimRequest;
  AuthRequest authRequest;
  SignatureRequest signature;

  bytes16 immutable APP_ID_ZK_DROP = 0x11b1de449c6c4adb0b5775b3868b28b3;
  bytes16 immutable ZK = 0xe9ed316946d3d98dfcd829a53ec9822e;
  ZKDropERC721 zkdrop;

  function setUp() public virtual override {
    super.setUp();
    sismoConnect = new SismoConnectHarness(DEFAULT_APP_ID, DEFAULT_IS_IMPERSONATION_MODE);
    claimRequest = sismoConnect.exposed_buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    authRequest = sismoConnect.exposed_buildAuth({authType: AuthType.VAULT});
    signature = sismoConnect.exposed_buildSignature({message: abi.encode(user)});

    zkdrop = new ZKDropERC721({
      config: SismoConnectConfigBuilder.build({appId: APP_ID_ZK_DROP}),
      groupId: ZK,
      name: "ZKDrop test",
      symbol: "test",
      baseTokenURI: "https://test.com"
    });
    console.log("ZkDrop contract deployed at", address(zkdrop));
  }

  function test_SismoConnectLibWithOnlyClaimAndMessage() public {
    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithOneClaimAndSignature(
      commitmentMapperRegistry
    );

    sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: requestBuilder.build({
        claim: sismoConnect.exposed_buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e}),
        signature: sismoConnect.exposed_buildSignature({message: abi.encode(user)})
      })
    });
  }

  function test_SismoConnectLibWithTwoClaimsAndMessage() public {
    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithTwoClaimsAndSignature(
      commitmentMapperRegistry
    );

    ClaimRequest[] memory claims = new ClaimRequest[](2);
    claims[0] = sismoConnect.exposed_buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    claims[1] = sismoConnect.exposed_buildClaim({groupId: 0x02d241fdb9d4330c564ffc0a36af05f6});

    sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: requestBuilder.build({
        claims: claims,
        signature: sismoConnect.exposed_buildSignature({message: abi.encode(user)})
      })
    });
  }

  function test_SismoConnectLibWithOnlyOneAuth() public {
    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithOnlyOneAuthAndMessage(
      commitmentMapperRegistry
    );

    SismoConnectRequest memory request = requestBuilder.build({
      auth: sismoConnect.exposed_buildAuth({authType: AuthType.VAULT}),
      signature: signature
    });

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify(
      responseEncoded,
      request
    );
    assertTrue(verifiedResult.auths[0].userId != 0);
  }

  function test_SismoConnectLibWithClaimAndAuth() public {
    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithOneClaimOneAuthAndOneMessage(
      commitmentMapperRegistry
    );
    SismoConnectRequest memory request = requestBuilder.build({
      auth: sismoConnect.exposed_buildAuth({authType: AuthType.VAULT}),
      claim: sismoConnect.exposed_buildClaim({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e}),
      signature: signature
    });

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify(
      responseEncoded,
      request
    );
    assertTrue(verifiedResult.auths[0].userId != 0);
  }

  function test_ClaimAndAuthWithSignedMessageZKDROP() public {
    // address that reverts if not modulo SNARK_FIELD after hashing the signedMessage for the circuit
    // should keep this address for testing purposes
    user = 0x040200040600000201150028570102001e030E26;

    // update EdDSA public key for proof made in dev.beta environment
    uint256[2] memory devBetaCommitmentMapperPubKey = [
      0x2ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f0256,
      0x30423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db74
    ];
    commitmentMapperRegistry.updateCommitmentMapperEdDSAPubKey(devBetaCommitmentMapperPubKey);

    // proof of membership for user in group 0xe9ed316946d3d98dfcd829a53ec9822e
    // vault ownership
    // signedMessage: 0x040200040600000201150028570102001e030E26
    bytes
      memory responseEncoded = hex"000000000000000000000000000000000000000000000000000000000000002011b1de449c6c4adb0b5775b3868b28b300000000000000000000000000000000b8e2054f8a912367e38a22ce773328ff000000000000000000000000000000007369736d6f2d636f6e6e6563742d76312e31000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000040200040600000201150028570102001e030e2600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001a068796472612d73332e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000004a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000118202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0000a2492461f347c2bb6bee55ea876f26ac2e0ad62d9303b5e620caad863fb1b1a99ed24846836b3a4d9317300ee131fae3c88be7cd6c5d3e314772cbaab1dfe1f66f706a4b50a671d058688321410d2773efe54d5d8da7e163d6b2b89fc0ba72cd815c044e2b28d49fc2189424f5cac9d3e215928b278817f0b43486cdcd6c30127366f061e09a1f5bba5aba989f69c698104f60887282c8b6db3c8be228f2f163017a534021fcc228e43808c24dfc61fc6974304c02a086d53f18a610592f8258df0bfed916e2cda15dc27f1c9a804db0248bdb15827340f66a27a8d82c9582844527baf97f27e5d4b72345fd5486e0dd31185ef3b1819ab0848b9249d41ec00000000000000000000000000000000000000000000000000000000000000001e762fcc1e79cf55469b1e6ada7c8f80734bc7484f73098f3168be945a2c00842ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f025630423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d01935d4d418952220ae0332606f61de2894d8b84c3076e6097ef3746a1ba04a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000c068796472612d73332e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000004c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000e9ed316946d3d98dfcd829a53ec9822e000000000000000000000000000000006c617465737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c01542fd96480d88341c3cc0e5b5ce789f596874284d1abe5e451be24e573462fd2ef6145919e53dff558c86f64a93b684f07f744e68d40b85a20f73a58f0b3c050a66a5aca29660cce60d6a991eb4434589334c81569e2f064686ab143a8c0a412e125c91202c2f7240c14ed0bed2ab5e863fa5423f142278bc45d386dff7e70d1d36e81a5399327e6a59489b8be26add10fdd27838ba7be6dbf73f5a02d3aaa221ea0487281d4f6898e84e0416e9d8b96279ac6a27e94cb10ba46375e4e6ddcb303e9c645ac300748745d119ee85bc45724966823f9831064cb5f3959f28514a03995e3c2245624fef7db86a0eb430493f093b2762638aec1bb388c48fc7f2d900000000000000000000000000000000000000000000000000000000000000001e762fcc1e79cf55469b1e6ada7c8f80734bc7484f73098f3168be945a2c00842ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f025630423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db740e997b7c2deffed71b40ef4b01f6a350824d1c54684dd64ea008ff355a2f9a1504f81599b826fa9b715033e76e5b2fdda881352a9b61360022e30ee33ddccad90744e9b92802056c722ac4b31612e1b1de544d5b99481386b162a0b59862e0850000000000000000000000000000000000000000000000000000000000000001285bf79dc20d58e71b9712cb38c420b9cb91d3438c8e3dbaf07829b03ffffffc000000000000000000000000000000000000000000000000000000000000000018202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d01935d4d418952220ae0332606f61de2894d8b84c3076e6097ef3746a1ba04a5000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    zkdrop.claimWithSismoConnect(responseEncoded, user);
  }

  function test_TwoClaimsOneVaultAuthWithSignature() public {
    ClaimRequest[] memory claims = new ClaimRequest[](2);
    claims[0] = claimRequestBuilder.build({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    claims[1] = claimRequestBuilder.build({groupId: 0x02d241fdb9d4330c564ffc0a36af05f6});

    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = authRequestBuilder.build({authType: AuthType.VAULT});

    SismoConnectRequest memory request = requestBuilder.build({
      claims: claims,
      auths: auths,
      signature: signature
    });

    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithTwoClaimsOneAuthAndOneSignature(
      commitmentMapperRegistry
    );

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: request
    });
    console.log("Claims in Verified result: %s", verifiedResult.claims.length);
  }

  function test_ThreeClaimsOneVaultAuthWithSignatureOneClaimOptional() public {
    ClaimRequest[] memory claims = new ClaimRequest[](3);
    claims[0] = claimRequestBuilder.build({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    claims[1] = claimRequestBuilder.build({groupId: 0x02d241fdb9d4330c564ffc0a36af05f6});
    claims[2] = claimRequestBuilder.build({
      groupId: 0x42c768bb8ae79e4c5c05d3b51a4ec74a,
      isOptional: true,
      isSelectableByUser: false
    });

    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = authRequestBuilder.build({authType: AuthType.VAULT});

    SismoConnectRequest memory request = requestBuilder.build({
      claims: claims,
      auths: auths,
      signature: signature
    });

    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithTwoClaimsOneAuthAndOneSignature(
      commitmentMapperRegistry
    );

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: request
    });
    console.log("Claims in Verified result: %s", verifiedResult.claims.length);
  }

  function test_ThreeClaimsOneVaultAuthOneTwitterAuthWithSignatureOneClaimOptionalAndTwitterAuthOptional()
    public
  {
    ClaimRequest[] memory claims = new ClaimRequest[](3);
    claims[0] = claimRequestBuilder.build({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});
    claims[1] = claimRequestBuilder.build({groupId: 0x02d241fdb9d4330c564ffc0a36af05f6});
    claims[2] = claimRequestBuilder.build({
      groupId: 0x42c768bb8ae79e4c5c05d3b51a4ec74a,
      isOptional: true,
      isSelectableByUser: false
    });

    AuthRequest[] memory auths = new AuthRequest[](2);
    auths[0] = authRequestBuilder.build({authType: AuthType.VAULT});
    auths[1] = authRequestBuilder.build({
      authType: AuthType.TWITTER,
      isOptional: true,
      isSelectableByUser: true
    });

    SismoConnectRequest memory request = requestBuilder.build({
      claims: claims,
      auths: auths,
      signature: signature
    });

    (, bytes memory responseEncoded) = hydraS3Proofs.getResponseWithTwoClaimsOneAuthAndOneSignature(
      commitmentMapperRegistry
    );

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: request
    });
    console.log("Claims in Verified result: %s", verifiedResult.claims.length);
  }

  function test_OneClaimOneOptionalTwitterAuthOneGithubAuthWithSignature() public {
    commitmentMapperRegistry.updateCommitmentMapperEdDSAPubKey(
      hydraS3Proofs.getEdDSAPubKeyDevBeta()
    );

    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claimRequestBuilder.build({groupId: 0xe9ed316946d3d98dfcd829a53ec9822e});

    AuthRequest[] memory auths = new AuthRequest[](2);
    auths[0] = authRequestBuilder.build({authType: AuthType.GITHUB});
    auths[1] = authRequestBuilder.build({
      authType: AuthType.TWITTER,
      isOptional: true,
      isSelectableByUser: true
    });

    SismoConnectRequest memory request = requestBuilder.build({
      claims: claims,
      auths: auths,
      signature: signature
    });

    bytes
      memory responseEncoded = hex"000000000000000000000000000000000000000000000000000000000000002011b1de449c6c4adb0b5775b3868b28b300000000000000000000000000000000b8e2054f8a912367e38a22ce773328ff000000000000000000000000000000007369736d6f2d636f6e6e6563742d76312e31000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000200000000000000000000000007def1d6d28d6bda49e69fa89ad75d160becba3ae00000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000052000000000000000000000000000000000000000000000000000000000000009e000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001a068796472612d73332e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000004a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000100100000000000000000000000000009999037000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0021e9b41aaf3e0f9687ed5a437ac6cf8201e3482ccd7d44869b2027c5ba058b62b3236f0fbca4f90f865e20de8a877bd821f1389dfe387c7ac9c23ef127dee5c092058481ee05164f428ff9a0b289aeb49a8b2c97cfe7aa23f81dbdfd18c06d822f0b1fb1266f186996d2f0b03f67483f75108a5b1870bfd8442bb76b97577bc2d45614da09da8c981833dff721eabcfd87fb5d880c26f6b89e79d20a1ff264a1cd56353a9e222ce3520a830c8faaf86f860461c5313d59419ee79cdaa852a0d0d7e0a3ab985983de4dce32ea2bfcd6a60a6cc8db89065e3844c43952bd9283f21153f58a4968b2f4ee160309d41ac55571c2155834bacd72bd2eb78a6e99c14000000000000000000000000100100000000000000000000000000009999037009f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d2ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f025630423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d01935d4d418952220ae0332606f61de2894d8b84c3076e6097ef3746a1ba04a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001a068796472612d73332e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000004a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000100200000000000000000000000000288480976500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c00de19a2044e5107fa0240d67260e3672865aa14a5e4d9215b28e76e0cfe46e000a5b7dd0f5c4b7f46fca1328eb2df7960b5f4a6070e60f2b9a1ff4c3bd739d260adc60091f5857cb01105dc17e96661878fd9fc6818fe32c7fd8735913e9673316ab2625bde124325fbab306f7ce07a6119eb4bc9ccfef5ede58a8feb0998cec0c907001eacc9081d94250580224873ca4571e771f11f38176765ca57dc6cb9c187abc1ec87e1f4e826768c18c5ce4cdc4713c16615d7b2c399f110e50c800bc215a487f5c109a9366c3a8e6a5351482400939dfc3ccc3a12200189188f878fd194fd94528baff867b6b51112c66214d9265e0aa87c90ce3ef0b133a9e7bd449000000000000000000000000100200000000000000000000000000288480976509f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d2ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f025630423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d01935d4d418952220ae0332606f61de2894d8b84c3076e6097ef3746a1ba04a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000c068796472612d73332e310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000004c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000e9ed316946d3d98dfcd829a53ec9822e000000000000000000000000000000006c617465737400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c028def7e5c4165ab2cae42e40461ea0f1f188220ad35333dfe66ecc07f884d2a32607c2130f9fb55e194236788d34a18fdae4d7d5ae279fbacdd8f54c0c2ef27e18f0389880b72a7d78b2f8919d51a24e9e45db6f83a95d6dad222b880847ab6d023424b98537b0e20da37266990490a15253df5e91c42bcac81c6c0950f5fa1026de21012517ce0a49328c9fb14a3e82478263e162afedf6eefe7e2db347fd6c0fbe00674b33a12e0271b68bd25826b29179fbed32854ef02ec2658a26e6f23618fd3981a5e462afa13de3f434c23c90fe92c73a97e8c28380e9d7031156e79c11e3f773704f7333a6886ca6a24cd514718a5b12be54bcddac80b530c2d98ecd000000000000000000000000000000000000000000000000000000000000000009f60d972df499264335faccfc437669a97ea2b6c97a1a7ddf3f0105eda34b1d2ab71fb864979b71106135acfa84afc1d756cda74f8f258896f896b4864f025630423b4c502f1cd4179a425723bf1e15c843733af2ecdee9aef6a0451ef2db740e997b7c2deffed71b40ef4b01f6a350824d1c54684dd64ea008ff355a2f9a1504f81599b826fa9b715033e76e5b2fdda881352a9b61360022e30ee33ddccad90744e9b92802056c722ac4b31612e1b1de544d5b99481386b162a0b59862e0850000000000000000000000000000000000000000000000000000000000000001285bf79dc20d58e71b9712cb38c420b9cb91d3438c8e3dbaf07829b03ffffffc000000000000000000000000000000000000000000000000000000000000000018202c14c40a8bc84b8fc8748836190f53fc45c66ad969c7bfa2a91afdd1ad8d01935d4d418952220ae0332606f61de2894d8b84c3076e6097ef3746a1ba04a5000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    SismoConnectVerifiedResult memory verifiedResult = sismoConnect.exposed_verify({
      responseBytes: responseEncoded,
      request: request
    });
    console.log("Claims in Verified result: %s", verifiedResult.claims.length);
  }

  function test_GitHubAuth() public {
    (, bytes memory encodedResponse) = hydraS3Proofs.getResponseWithGitHubAuth(
      commitmentMapperRegistry
    );

    SismoConnectRequest memory request = requestBuilder.build({
      auth: sismoConnect.exposed_buildAuth({authType: AuthType.GITHUB}),
      signature: signature
    });

    sismoConnect.exposed_verify({responseBytes: encodedResponse, request: request});
  }

  function test_GitHubAuthWithoutSignature() public {
    (, bytes memory encodedResponse) = hydraS3Proofs.getResponseWithGitHubAuthWithoutSignature(
      commitmentMapperRegistry
    );

    SismoConnectRequest memory request = requestBuilder.build({
      auth: sismoConnect.exposed_buildAuth({authType: AuthType.GITHUB})
    });

    sismoConnect.exposed_verify({responseBytes: encodedResponse, request: request});
  }

  // helpers

  function emptyResponse() private pure returns (SismoConnectResponse memory) {
    return ResponseBuilder.empty();
  }
}
