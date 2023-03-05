import { Address } from "@graphprotocol/graph-ts";

export const ZERO_ADDR = '0x0000000000000000000000000000000000000000'


export function formatAddress(address: Address): string {
  return address.toHexString().toLowerCase();
}

export function join(parts: string[]): string {
  return parts.join("-");
}