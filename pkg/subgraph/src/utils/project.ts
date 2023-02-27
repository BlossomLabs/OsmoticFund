import { Address, Bytes } from "@graphprotocol/graph-ts";
import {
  ProjectRegistry as ProjectRegistryEntity,
  Project as ProjectEntity,
} from "../../generated/schema";
import { formatAddress, join, ZERO_ADDR } from "./ids";

function buildProjectRegistryId(projectRegistry: Address): string {
  return formatAddress(projectRegistry);
}

function buildProjectId(
  projectRegistry: Address,
  projectBeneficiary: Address
): string {
  return join([
    formatAddress(projectRegistry),
    formatAddress(projectBeneficiary)
  ]);
}

export function loadOrCreateProjectRegistryEntity(
  projectRegistry: Address
): ProjectRegistryEntity {
  const projectRegistryId = buildProjectRegistryId(projectRegistry);

  let projectRegistryEntity = ProjectRegistryEntity.load(projectRegistryId);

  if (projectRegistryEntity == null) {
    projectRegistryEntity = new ProjectRegistryEntity(projectRegistryId);
  }

  return projectRegistryEntity;
}

export function loadOrCreateProjectEntity(
  projectRegistry: Address,
  projectBeneficiary: Address
): ProjectEntity {
  const projectId = buildProjectId(projectRegistry, projectBeneficiary);

  let projectEntity = ProjectEntity.load(projectId);

  if (projectEntity == null) {
    projectEntity = new ProjectEntity(projectId);
    projectEntity.admin = Address.fromI32(0);
    projectEntity.beneficiary = Bytes.fromHexString(
      projectBeneficiary.toHexString()
    );
    projectEntity.contentHash = Bytes.fromHexString("0x");
    projectEntity.projectRegistry = buildProjectRegistryId(projectRegistry);
  }

  return projectEntity;
}
