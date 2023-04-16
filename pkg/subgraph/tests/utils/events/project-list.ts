import { BigInt } from "@graphprotocol/graph-ts";
import { newMockEvent } from "matchstick-as";

import { ListUpdated as ListUpdatedEvent } from "../../../generated/templates/OwnableProjectList/OwnableProjectList";
import { getBigIntEventParam, getBooleanEventParam } from "../converters";

export function createListUpdatedEvent(
  projectId: BigInt,
  included: boolean
): ListUpdatedEvent {
  // @ts-ignore
  const listUpdatedEvent = changetype<ListUpdatedEvent>(newMockEvent());

  listUpdatedEvent.parameters = new Array();
  listUpdatedEvent.parameters.push(getBigIntEventParam("projectId", projectId));
  listUpdatedEvent.parameters.push(getBooleanEventParam("included", included));

  return listUpdatedEvent;
}
