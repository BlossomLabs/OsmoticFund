import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { newMockEvent } from "matchstick-as";
import { ProjectUpdated as ProjectUpdatedEvent } from "../../../generated/templates/ProjectRegistry/ProjectRegistry";
import {
  getAddressEventParam,
  getBigIntEventParam,
  getBytesEventParam,
} from "../converters";

export function createProjectUpdatedEvent(
  projectId: BigInt,
  admin: string,
  contentHash: Bytes,
  beneficiary: string
): ProjectUpdatedEvent {
  // @ts-ignore
  const projectUpdatedEvent = changetype<ProjectUpdatedEvent>(newMockEvent());

  projectUpdatedEvent.parameters = new Array();
  projectUpdatedEvent.parameters.push(
    getBigIntEventParam("projectId", projectId)
  );
  projectUpdatedEvent.parameters.push(getAddressEventParam("admin", admin));
  projectUpdatedEvent.parameters.push(
    getAddressEventParam("beneficiary", beneficiary)
  );
  projectUpdatedEvent.parameters.push(
    getBytesEventParam("contenthash", contentHash)
  );

  return projectUpdatedEvent;
}
