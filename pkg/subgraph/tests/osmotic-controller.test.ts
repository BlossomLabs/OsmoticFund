import { assert, beforeEach, clearStore, describe, test } from "matchstick-as";

import { handleMimeTokenCreated } from "../src/mappings/OsmoticController";
import { createMimeTokenCreatedEvent, mockedTokenRPCCalls } from "./utils";

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
});
