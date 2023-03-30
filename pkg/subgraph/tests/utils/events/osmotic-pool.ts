import { BigInt } from "@graphprotocol/graph-ts";
import { newMockEvent } from "matchstick-as";

import { getAddressEventParam, getBigIntEventParam } from "../converters";
import {
  FlowSynced as FlowSyncedEvent,
  OsmoticParamsChanged as OsmoticParamsChangedEvent,
  ProjectActivated as ProjectActivatedEvent,
  ProjectDeactivated as ProjectDeactivatedEvent,
  ProjectSupportUpdated as ProjectSupportUpdatedEvent,
} from "../../../generated/templates/OsmoticPool/OsmoticPool";

export function createProjectActivatedEvent(
  projectIndex: BigInt
): ProjectActivatedEvent {
  // @ts-ignore
  const projectActivatedEvent = changetype<ProjectActivatedEvent>(
    newMockEvent()
  );

  projectActivatedEvent.parameters = new Array();
  projectActivatedEvent.parameters.push(
    getBigIntEventParam("projectId", projectIndex)
  );

  return projectActivatedEvent;
}

export function createProjectDeactivated(
  projectIndex: BigInt
): ProjectDeactivatedEvent {
  // @ts-ignore
  const projectDectivatedEvent = changetype<ProjectDeactivatedEvent>(
    newMockEvent()
  );

  projectDectivatedEvent.parameters = new Array();
  projectDectivatedEvent.parameters.push(
    getBigIntEventParam("projectId", projectIndex)
  );

  return projectDectivatedEvent;
}

export function createProjectSupportUpdated(
  round: BigInt,
  projectIndex: BigInt,
  participant: string,
  delta: BigInt
): ProjectSupportUpdatedEvent {
  // @ts-ignore
  const projectSupportUpdatedEvent = changetype<ProjectSupportUpdatedEvent>(
    newMockEvent()
  );

  projectSupportUpdatedEvent.parameters = new Array();
  projectSupportUpdatedEvent.parameters.push(
    getBigIntEventParam("round", round)
  );
  projectSupportUpdatedEvent.parameters.push(
    getBigIntEventParam("projectId", projectIndex)
  );
  projectSupportUpdatedEvent.parameters.push(
    getAddressEventParam("participant", participant)
  );
  projectSupportUpdatedEvent.parameters.push(
    getBigIntEventParam("delta", delta)
  );

  return projectSupportUpdatedEvent;
}

export function createOsmoticParamsChanged(
  decay: BigInt,
  drop: BigInt,
  maxFlow: BigInt,
  minStakeRatio: BigInt
): OsmoticParamsChangedEvent {
  // @ts-ignore
  const osmoticParamsChangedEvent = changetype<OsmoticParamsChangedEvent>(
    newMockEvent()
  );

  osmoticParamsChangedEvent.parameters = new Array();

  osmoticParamsChangedEvent.parameters.push(
    getBigIntEventParam("decay", decay)
  );
  osmoticParamsChangedEvent.parameters.push(getBigIntEventParam("drop", drop));

  osmoticParamsChangedEvent.parameters.push(
    getBigIntEventParam("maxFlow", maxFlow)
  );

  osmoticParamsChangedEvent.parameters.push(
    getBigIntEventParam("minStakeRatio", minStakeRatio)
  );

  return osmoticParamsChangedEvent;
}

export function createFlowSynced(
  projectIndex: BigInt,
  beneficiary: string,
  flowRate: BigInt
): FlowSyncedEvent {
  // @ts-ignore
  const flowSyncedEvent = changetype<FlowSyncedEvent>(newMockEvent());

  flowSyncedEvent.parameters = new Array();
  flowSyncedEvent.parameters.push(
    getBigIntEventParam("projectId", projectIndex)
  );
  flowSyncedEvent.parameters.push(
    getAddressEventParam("beneficiary", beneficiary)
  );
  flowSyncedEvent.parameters.push(getBigIntEventParam("flowRate", flowRate));

  return flowSyncedEvent;
}
