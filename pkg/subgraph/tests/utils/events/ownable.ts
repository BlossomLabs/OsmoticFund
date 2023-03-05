import { newMockEvent } from "matchstick-as";

import { getAddressEventParam } from "../converters";

/**
 * Note: Need to use `T` as the return type to avoid a event mismatch error
 * when using this function in different mapping tests
 *  */
export function createOwnershipTransferredEvent<T>(
  previousOwner: string,
  newOwner: string
): T {
  // @ts-ignore
  const ownershipTransferredEvent = changetype<T>(newMockEvent());

  ownershipTransferredEvent.parameters = new Array();
  ownershipTransferredEvent.parameters.push(
    getAddressEventParam("previousOwner", previousOwner)
  );
  ownershipTransferredEvent.parameters.push(
    getAddressEventParam("newOwner", newOwner)
  );

  return ownershipTransferredEvent;
}
