import { Address } from "@graphprotocol/graph-ts";

import { ZERO_ADDR } from "../../src/utils/ids";

export function generateAddress(
  // @ts-ignore
  index: i32
): Address {
  const index_ = index.toString();

  return Address.fromString(ZERO_ADDR.slice(0, -index_.length) + index_);
}
