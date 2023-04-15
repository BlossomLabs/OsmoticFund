import { Address, BigInt } from "@graphprotocol/graph-ts";

import {
  OsmoticPool,
  FlowSynced as FlowSyncedEvent,
  OsmoticParamsChanged as OsmoticParamsChangedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  ProjectActivated as ProjectActivatedEvent,
  ProjectDeactivated as ProjectDeactivatedEvent,
  ProjectSupportUpdated as ProjectSupportUpdatedEvent,
} from "../../generated/templates/OsmoticPool/OsmoticPool";
import { OsmoticController } from "../../generated/templates/OsmoticPool/OsmoticController";
import { PoolProject as PoolProjectEntity } from "../../generated/schema";

import {
  buildOsmoticPoolId,
  loadOrCreateOsmoticParams,
  loadOrCreateOsmoticPool,
  loadOrCreatePoolProject,
  loadOrCreatePoolProjectParticipantSupport,
  loadOrCreatePoolProjectSupport,
} from "../utils/osmotic-pool";
import { buildProjectId } from "../utils/project";

export function handleProjectActivated(event: ProjectActivatedEvent): void {
  const poolProject = getPoolProjectEntity(
    event.address,
    event.params.projectId
  );

  poolProject.active = true;
  poolProject.save();
}

export function handleProjectDeactivated(event: ProjectDeactivatedEvent): void {
  const poolProject = getPoolProjectEntity(
    event.address,
    event.params.projectId
  );

  poolProject.active = false;

  poolProject.save();
}

export function handleProjectSupportUpdated(
  event: ProjectSupportUpdatedEvent
): void {
  const poolProject = getPoolProjectEntity(
    event.address,
    event.params.projectId
  );
  const poolProjectSupport = loadOrCreatePoolProjectSupport(
    poolProject.id,
    event.params.round
  );
  const poolProjectParticipantSupport =
    loadOrCreatePoolProjectParticipantSupport(
      poolProjectSupport.id,
      event.params.participant
    );

  poolProjectSupport.support = poolProjectSupport.support.plus(
    event.params.delta
  );
  poolProjectParticipantSupport.support =
    poolProjectParticipantSupport.support.plus(event.params.delta);

  poolProject.save();
  poolProjectSupport.save();
  poolProjectParticipantSupport.save();
}

export function handleFlowSynced(event: FlowSyncedEvent): void {
  const poolProject = getPoolProjectEntity(
    event.address,
    event.params.projectId
  );

  /**
   * Note: No need to update project entity's beneficiary as it
   * has been already done in the ProjectUpdated mapping handler
   */

  poolProject.flowLastRate = event.params.flowRate;
  poolProject.flowLastTime = event.block.timestamp;

  poolProject.save();
}

export function handleOsmoticParamsChanged(
  event: OsmoticParamsChangedEvent
): void {
  const osmoticParams = loadOrCreateOsmoticParams(event.address);

  osmoticParams.decay = event.params.decay;
  osmoticParams.drop = event.params.drop;
  osmoticParams.maxFlow = event.params.maxFlow;
  osmoticParams.minStakeRatio = event.params.minStakeRatio;

  osmoticParams.save();
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  const osmoticPool = loadOrCreateOsmoticPool(event.address);

  osmoticPool.owner = event.params.newOwner;

  osmoticPool.save();
}

function getPoolProjectEntity(
  poolAddress: Address,
  projectIndex: BigInt
): PoolProjectEntity {
  const osmoticPool = OsmoticPool.bind(poolAddress);
  const osmoticController = OsmoticController.bind(osmoticPool.controller());
  const projectRegistryAddress = osmoticController.projectRegistry();
  const osmoticPoolId = buildOsmoticPoolId(poolAddress);
  const projectId = buildProjectId(projectRegistryAddress, projectIndex);

  return loadOrCreatePoolProject(osmoticPoolId, projectId);
}
