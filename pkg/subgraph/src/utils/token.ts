import { Address } from "@graphprotocol/graph-ts";

import { MimeToken as MimeTokenContract } from "../../generated/OsmoticController/MimeToken";
import { Token as TokenEntity } from "../../generated/schema";

import { formatAddress } from "./ids";

function buildTokenId(address: Address): string {
  return formatAddress(address);
}

export function loadOrCreateTokenEntity(tokenAddress: Address): TokenEntity {
  const tokenId = buildTokenId(tokenAddress);

  let token = TokenEntity.load(tokenId);
  if (token == null) {
    token = new TokenEntity(tokenId);

    // we use MimeTokenContract to get the token's name, symbol and decimals
    const tokenContract = MimeTokenContract.bind(tokenAddress);

    token.name = tokenContract.name();
    token.symbol = tokenContract.symbol();
    token.decimals = tokenContract.decimals();

    token.save();
  }

  return token;
}
