import { newMockEvent } from "matchstick-as";

import { getAddressEventParam } from "../converters";
import { OwnershipTransferred as OwnershipTransferredEvent } from "../../../generated/ProjectRegistry/ProjectRegistry";

export function createOwnershipTransferredEvent(
  previousOwner: string,
  newOwner: string
): OwnershipTransferredEvent {
  // @ts-ignore
  const ownershipTransferredEvent = changetype<OwnershipTransferredEvent>(
    newMockEvent()
  );

  ownershipTransferredEvent.parameters = new Array();
  ownershipTransferredEvent.parameters.push(
    getAddressEventParam("previousOwner", previousOwner)
  );
  ownershipTransferredEvent.parameters.push(
    getAddressEventParam("newOwner", newOwner)
  );

  return ownershipTransferredEvent
}
