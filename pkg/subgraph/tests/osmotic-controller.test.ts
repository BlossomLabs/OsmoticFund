import { assert, beforeEach, clearStore, describe, test } from "matchstick-as";

import {
  handleMimeTokenCreated,
  handleOwnershipTransferred,
} from "../src/mappings/OsmoticController";
import {
  alice,
  bob,
  createMimeTokenCreatedEvent,
  createOwnershipTransferredEvent,
  generateAddress,
  mockedProjectRegistryRPCCall,
  mockedTokenRPCCalls,
  mockedVersionRPCCall,
} from "./utils";
import { OwnershipTransferred } from "../generated/OsmoticController/OsmoticController";
import { buildOsmoticControllerId } from "../src/utils/osmotic-controller";
import { buildProjectRegistryId } from "../src/utils/project";

describe("when mapping OsmoticController events", () => {
  beforeEach(() => {
    clearStore();
  });

  test("should map MimeTokenCreated event correctly", () => {
    const mimeToken = "0x70a3f5b01a444ec6e58c6985b9672bfc1a91c792";
    const tokenDecimals = 18;
    const tokenName = "mimeToken";
    const tokenSymbol = "MT";
    const mimeTokenCreatedEvent = createMimeTokenCreatedEvent(mimeToken);

    mockedTokenRPCCalls(mimeToken, tokenDecimals, tokenName, tokenSymbol);

    handleMimeTokenCreated(mimeTokenCreatedEvent);

    assert.fieldEquals("Token", mimeToken, "id", mimeToken);
    assert.fieldEquals(
      "Token",
      mimeToken,
      "decimals",
      tokenDecimals.toString()
    );
    assert.fieldEquals("Token", mimeToken, "name", tokenName);
    assert.fieldEquals("Token", mimeToken, "symbol", tokenSymbol);
  });

  // TODO: test OsmoticPoolCreated and ProjectListCreated events

  test("should map OwnershipTransferred correctly", () => {
    const projectRegistryAddress = generateAddress(1);
    const projectRegistryId = buildProjectRegistryId(projectRegistryAddress);

    const ownershipTransferredEvent =
      createOwnershipTransferredEvent<OwnershipTransferred>(alice, bob);
    const osmoticControllerAddress = ownershipTransferredEvent.address;
    const osmoticControllerId = buildOsmoticControllerId(
      osmoticControllerAddress
    );

    mockedVersionRPCCall(osmoticControllerId, 1);
    mockedProjectRegistryRPCCall(osmoticControllerId, projectRegistryId);
    mockedVersionRPCCall(projectRegistryId, 1);

    handleOwnershipTransferred(ownershipTransferredEvent);

    assert.fieldEquals("OsmoticController", osmoticControllerId, "owner", bob);
  });
});
