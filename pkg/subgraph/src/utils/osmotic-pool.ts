import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";

import {
  OsmoticParams as OsmoticParamsEntity,
  OsmoticPool as OsmoticPoolEntity,
  PoolProject as PoolProjectEntity,
  PoolProjectParticipantSupport as PoolProjectParticipantSupportEntity,
  PoolProjectSupport as PoolProjectSupportEntity,
} from "../../generated/schema";
import { OsmoticPool } from "../../generated/templates/OsmoticPool/OsmoticPool";

import { formatAddress, join, ZERO_ADDR } from "./ids";
import { loadOrCreateTokenEntity } from "./token";

export function buildOsmoticPoolId(poolAddress: Address): string {
  return formatAddress(poolAddress);
}

export function buildPoolProjectId(
  osmoticPoolId: string,
  projectId: string
): string {
  return join([osmoticPoolId, projectId]);
}

export function buildPoolProjectSupportId(
  poolProjectId: string,
  round: BigInt
): string {
  return join([poolProjectId, round.toString()]);
}

export function buildPoolProjectParticipantSupportId(
  poolProjectSupportId: string,
  participant: Address
): string {
  return join([poolProjectSupportId, formatAddress(participant)]);
}

export function buildOsmoticParamsId(osmoticPool: Address): string {
  return formatAddress(osmoticPool);
}

export function loadOrCreateOsmoticPool(
  poolAddress: Address
): OsmoticPoolEntity {
  const id = buildOsmoticPoolId(poolAddress);

  let osmoticPool = OsmoticPoolEntity.load(id);

  if (osmoticPool == null) {
    osmoticPool = new OsmoticPoolEntity(id);

    const osmoticPoolContract = OsmoticPool.bind(poolAddress);

    osmoticPool.address = poolAddress;
    osmoticPool.owner = Bytes.fromHexString(ZERO_ADDR);
    osmoticPool.osmoticController = formatAddress(
      osmoticPoolContract.controller()
    );
    osmoticPool.maxActiveProjects = osmoticPoolContract.MAX_ACTIVE_PROJECTS();
    osmoticPool.fundingToken = loadOrCreateTokenEntity(osmoticPoolContract.fundingToken()).id;
    osmoticPool.mimeToken = loadOrCreateTokenEntity(osmoticPoolContract.mimeToken()).id;
    osmoticPool.projectList = formatAddress(osmoticPoolContract.projectList());
    osmoticPool.osmoticParams = loadOrCreateOsmoticParams(poolAddress).id;

    osmoticPool.save();
  }

  return osmoticPool;
}

export function loadOrCreatePoolProject(
  osmoticPoolId: string,
  projectId: string
): PoolProjectEntity {
  const id = buildPoolProjectId(osmoticPoolId, projectId);
  let poolProject = PoolProjectEntity.load(id);

  if (poolProject == null) {
    poolProject = new PoolProjectEntity(id);
    poolProject.osmoticPool = osmoticPoolId;
    poolProject.project = projectId;
    poolProject.active = false;
    poolProject.flowLastRate = BigInt.fromI32(0);
    poolProject.flowLastTime = BigInt.fromI32(0);
    poolProject.currentRound = BigInt.fromI32(0);

    poolProject.save();
  }

  return poolProject;
}

export function loadOrCreatePoolProjectSupport(
  poolProjectId: string,
  round: BigInt
): PoolProjectSupportEntity {
  const id = buildPoolProjectSupportId(poolProjectId, round);

  let poolProjectSupport = PoolProjectSupportEntity.load(id);

  if (poolProjectSupport === null) {
    poolProjectSupport = new PoolProjectSupportEntity(id);
    poolProjectSupport.poolProject = poolProjectId;
    poolProjectSupport.round = round;
    poolProjectSupport.support = BigInt.fromI32(0);

    poolProjectSupport.save();
  }

  return poolProjectSupport;
}

export function loadOrCreatePoolProjectParticipantSupport(
  poolProjectSupportId: string,
  participant: Address
): PoolProjectParticipantSupportEntity {
  const id = buildPoolProjectParticipantSupportId(
    poolProjectSupportId,
    participant
  );

  let poolProjectParticipantSupport =
    PoolProjectParticipantSupportEntity.load(id);

  if (poolProjectParticipantSupport === null) {
    poolProjectParticipantSupport = new PoolProjectParticipantSupportEntity(id);
    poolProjectParticipantSupport.poolProjectSupport = poolProjectSupportId;
    poolProjectParticipantSupport.participant = participant;
    poolProjectParticipantSupport.support = BigInt.fromI32(0);

    poolProjectParticipantSupport.save();
  }

  return poolProjectParticipantSupport;
}

export function loadOrCreateOsmoticParams(
  osmoticPool: Address
): OsmoticParamsEntity {
  const id = buildOsmoticParamsId(osmoticPool);

  let osmoticParams = OsmoticParamsEntity.load(id);

  if (osmoticParams === null) {
    osmoticParams = new OsmoticParamsEntity(id);

    osmoticParams.osmoticPool = formatAddress(osmoticPool);
    osmoticParams.decay = BigInt.fromI32(0);
    osmoticParams.drop = BigInt.fromI32(0);
    osmoticParams.maxFlow = BigInt.fromI32(0);
    osmoticParams.minStakeRatio = BigInt.fromI32(0);

    osmoticParams.save();
  }

  return osmoticParams;
}
