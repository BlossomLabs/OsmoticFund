import { store } from "@graphprotocol/graph-ts";

import {
  OwnableProjectList,
  ListUpdated as ListUpdatedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
} from "../../generated/templates/OwnableProjectList/OwnableProjectList";

import {
  loadOrCreateProjectListEntity,
  loadOrCreateProjectProjectListEntity,
} from "../utils/project";

export function handleListUpdated(event: ListUpdatedEvent): void {
  const projectListContract = OwnableProjectList.bind(event.address);
  const projectRegistry = projectListContract.projectRegistry();

  const projectProjectList = loadOrCreateProjectProjectListEntity(
    projectRegistry,
    event.address,
    event.params.projectId
  );

  if (!event.params.included) {
    store.remove("ProjectProjectList", projectProjectList.id);
  } else {
    projectProjectList.save();
  }
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  const projectList = loadOrCreateProjectListEntity(event.address);

  projectList.owner = event.params.newOwner;

  projectList.save();
}
