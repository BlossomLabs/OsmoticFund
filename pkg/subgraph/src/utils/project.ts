import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";

import {
  ProjectRegistry as ProjectRegistryEntity,
  Project as ProjectEntity,
  ProjectList as ProjectListEntity,
  ProjectProjectList as ProjectProjectListEntity,
} from "../../generated/schema";
import { OwnableProjectList } from "../../generated/templates/OwnableProjectList/OwnableProjectList";
import { ProjectRegistry } from "../../generated/templates/ProjectRegistry/ProjectRegistry";

import { formatAddress, join, ZERO_ADDR } from "./ids";

export function buildProjectRegistryId(projectRegistry: Address): string {
  return formatAddress(projectRegistry);
}

export function buildProjectId(
  projectRegistry: Address,
  projectIndex: BigInt
): string {
  return join([formatAddress(projectRegistry), projectIndex.toString()]);
}

export function buildProjectListId(projectList: Address): string {
  return formatAddress(projectList);
}

export function buildProjectProjectListId(
  projectRegistry: Address,
  projectId: BigInt,
  projectList: Address
): string {
  return join([
    buildProjectId(projectRegistry, projectId),
    formatAddress(projectList),
  ]);
}

export function loadOrCreateProjectRegistryEntity(
  registryAddress: Address
): ProjectRegistryEntity {
  const projectRegistryId = buildProjectRegistryId(registryAddress);

  let projectRegistryEntity = ProjectRegistryEntity.load(projectRegistryId);

  if (projectRegistryEntity == null) {
    projectRegistryEntity = new ProjectRegistryEntity(projectRegistryId);

    const projectRegistryContract = ProjectRegistry.bind(registryAddress);

    projectRegistryEntity.version = projectRegistryContract.version().toI32();
    projectRegistryEntity.owner = Bytes.fromHexString(ZERO_ADDR);

    projectRegistryEntity.save();
  }

  return projectRegistryEntity;
}

export function loadOrCreateProjectEntity(
  projectRegistry: Address,
  projectIndex: BigInt
): ProjectEntity {
  const projectEntityId = buildProjectId(projectRegistry, projectIndex);

  let projectEntity = ProjectEntity.load(projectEntityId);

  if (projectEntity == null) {
    projectEntity = new ProjectEntity(projectEntityId);
    projectEntity.admin = Bytes.fromHexString(ZERO_ADDR);
    projectEntity.beneficiary = Bytes.fromHexString(ZERO_ADDR);
    projectEntity.contentHash = Bytes.fromHexString(ZERO_ADDR);
    projectEntity.projectRegistry = buildProjectRegistryId(projectRegistry);

    projectEntity.save();
  }

  return projectEntity;
}

export function loadOrCreateProjectListEntity(
  projectList: Address
): ProjectListEntity {
  const projectListId = buildProjectListId(projectList);

  let projectListEntity = ProjectListEntity.load(projectListId);

  if (projectListEntity === null) {
    projectListEntity = new ProjectListEntity(projectListId);

    const projectListContract = OwnableProjectList.bind(projectList);

    projectListEntity.owner = Bytes.fromHexString(ZERO_ADDR);
    projectListEntity.name = projectListContract.name();
    projectListEntity.osmoticController = "";

    projectListEntity.save();
  }

  return projectListEntity;
}

export function loadOrCreateProjectProjectListEntity(
  projectRegistry: Address,
  projectList: Address,
  projectId: BigInt
): ProjectProjectListEntity {
  const projectProjectListId = buildProjectProjectListId(
    projectRegistry,
    projectId,
    projectList
  );

  let projectProjectListEntity =
    ProjectProjectListEntity.load(projectProjectListId);

  if (projectProjectListEntity === null) {
    projectProjectListEntity = new ProjectProjectListEntity(
      projectProjectListId
    );
    projectProjectListEntity.project = buildProjectId(
      projectRegistry,
      projectId
    );
    projectProjectListEntity.projectList = buildProjectListId(projectList);

    projectProjectListEntity.save();
  }

  return projectProjectListEntity;
}
