import {
  ProjectUpdated as ProjectUpdatedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
} from "../../generated/templates/ProjectRegistry/ProjectRegistry";

import {
  loadOrCreateProjectEntity,
  loadOrCreateProjectRegistryEntity,
} from "../utils/project";

export function handleProjectUpdated(event: ProjectUpdatedEvent): void {
  const project = loadOrCreateProjectEntity(
    event.address,
    event.params.projectId
  );

  project.admin = event.params.admin;
  project.contentHash = event.params.contenthash;
  project.beneficiary = event.params.beneficiary;

  project.save();
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  const projectRegistry = loadOrCreateProjectRegistryEntity(event.address);

  projectRegistry.owner = event.params.newOwner;

  projectRegistry.save();
}
