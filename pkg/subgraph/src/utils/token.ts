import { Address } from "@graphprotocol/graph-ts";
import { Token as TokenEntity } from '../../generated/schema'

function buildTokenId(address: Address): string {
  return address.toHexString().toLowerCase()
}

export function loadOrCreateTokenEntity(tokenAddress: Address): TokenEntity {
  const tokenId = buildTokenId(tokenAddress)

  let token = TokenEntity.load(tokenId)
  if (token == null) {
    token = new TokenEntity(tokenId)
  }

  return token
}