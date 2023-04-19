import { MimeToken as MimeTokenContract } from "../../generated/OsmoticController/MimeToken";
import {
  MimeTokenCreated as MimeTokenCreatedEvent,
  OsmoticPoolCreated as OsmoticPoolCreatedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  ProjectListCreated as ProjectListCreatedEvent,
} from "../../generated/OsmoticController/OsmoticController";
import {
  OsmoticPool as OsmoticPoolTemplate,
  OwnableProjectList as OwnableProjectListTemplate,
} from "../../generated/templates";

import { formatAddress } from "../utils/ids";
import { loadOrCreateOsmoticController } from "../utils/osmotic-controller";
import { loadOrCreateOsmoticPool } from "../utils/osmotic-pool";
import { loadOrCreateProjectListEntity } from "../utils/project";
import { loadOrCreateTokenEntity } from "../utils/token";

export function handleProjectListCreated(event: ProjectListCreatedEvent): void {
  const projectListAddress = event.params.list;
  const projectList = loadOrCreateProjectListEntity(projectListAddress);

  projectList.osmoticController = formatAddress(event.address);

  projectList.save();

  OwnableProjectListTemplate.create(projectListAddress);
}

export function handleOsmoticPoolCreated(event: OsmoticPoolCreatedEvent): void {
  const poolAddress = event.params.pool;
  const osmoticPool = loadOrCreateOsmoticPool(poolAddress);

  osmoticPool.osmoticController = formatAddress(event.address);

  osmoticPool.save();

  OsmoticPoolTemplate.create(poolAddress);
}

export function handleMimeTokenCreated(event: MimeTokenCreatedEvent): void {
  const token = loadOrCreateTokenEntity(event.params.token);
  const tokenContract = MimeTokenContract.bind(event.params.token);

  token.name = tokenContract.name();
  token.symbol = tokenContract.symbol();
  token.decimals = tokenContract.decimals();
  token.osmoticController = formatAddress(event.address);

  token.save();
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  const osmoticController = loadOrCreateOsmoticController(event.address);

  osmoticController.owner = event.params.newOwner;

  osmoticController.save();
}
