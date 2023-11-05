import { Address } from "@graphprotocol/graph-ts";

import { ERC20 as ERC20Contract } from "../../generated/OsmoticController/ERC20";
import { Token as TokenEntity } from "../../generated/schema";

import { formatAddress } from "./ids";

function buildTokenId(address: Address): string {
  return formatAddress(address);
}

export function loadOrCreateTokenEntity(tokenAddress: Address): TokenEntity {
  const tokenId = buildTokenId(tokenAddress);

  let token = TokenEntity.load(tokenId);
  if (token == null) {
    const tokenContract = ERC20Contract.bind(tokenAddress);

    token = new TokenEntity(tokenId);

    token.name = tokenContract.name();
    token.symbol = tokenContract.symbol();
    token.decimals = tokenContract.decimals();

    token.save();
  }

  return token;
}
