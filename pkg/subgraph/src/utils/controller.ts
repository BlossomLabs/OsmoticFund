import { Address } from "@graphprotocol/graph-ts";

export function buildOsmoticControllerId(osmoticController: Address): string {
  return osmoticController.toHexString();
}
