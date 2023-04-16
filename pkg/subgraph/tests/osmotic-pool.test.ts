import { Address, BigInt } from "@graphprotocol/graph-ts";
import {
  assert,
  beforeEach,
  clearStore,
  describe,
  test,
} from "matchstick-as";

import { OwnershipTransferred } from "../generated/templates/OsmoticPool/OsmoticPool";
import {
  handleFlowSynced,
  handleOsmoticParamsChanged,
  handleOwnershipTransferred,
  handleProjectActivated,
  handleProjectDeactivated,
  handleProjectSupportUpdated,
} from "../src/mappings/OsmoticPool";
import {
  buildOsmoticPoolId,
  buildPoolProjectId,
  buildPoolProjectSupportId,
  buildPoolProjectParticipantSupportId,
  buildOsmoticParamsId,
} from "../src/utils/osmotic-pool";
import { buildProjectId } from "../src/utils/project";
import {
  createFlowSynced,
  createOsmoticParamsChanged,
  createOwnershipTransferredEvent,
  createProjectActivatedEvent,
  createProjectDeactivated,
  createProjectSupportUpdated,
  FALSE,
  generateAddress,
  mockedOsmoticControllerRPCCall,
  mockedProjectRegistryRPCCall,
  TRUE,
} from "./utils";

function prepareMockedRPCCalls(
  osmoticPool: Address,
  osmoticController: Address,
  projectRegistry: Address
): void {
  const osmoticPool_ = osmoticPool.toHexString();
  const osmoticController_ = osmoticController.toHexString();
  const projectRegistry_ = projectRegistry.toHexString();

  mockedOsmoticControllerRPCCall(osmoticPool_, osmoticController_);
  mockedProjectRegistryRPCCall(osmoticController_, projectRegistry_);
}

function checkPoolProjectSupportUpdate(delta: BigInt): void {
  const round = BigInt.fromI32(1);
  const projectIndex = BigInt.fromI32(1);
  const osmoticControllerAddress = generateAddress(1);
  const projectRegistryAddress = generateAddress(2);
  const participantAddress = generateAddress(3);

  const projectSupportUpdatedEvent = createProjectSupportUpdated(
    round,
    projectIndex,
    participantAddress.toHexString(),
    delta
  );
  const osmoticPoolAddress = projectSupportUpdatedEvent.address;

  prepareMockedRPCCalls(
    osmoticPoolAddress,
    osmoticControllerAddress,
    projectRegistryAddress
  );

  handleProjectSupportUpdated(projectSupportUpdatedEvent);

  const poolProjectEntityId = buildPoolProjectId(
    buildOsmoticPoolId(osmoticPoolAddress),
    buildProjectId(projectRegistryAddress, projectIndex)
  );
  const poolProjectSupportEntityId = buildPoolProjectSupportId(
    poolProjectEntityId,
    round
  );
  const poolProjectParticipantSupportEntityId =
    buildPoolProjectParticipantSupportId(
      poolProjectSupportEntityId,
      participantAddress
    );

  assert.fieldEquals(
    "PoolProjectSupport",
    poolProjectSupportEntityId,
    "poolProject",
    poolProjectEntityId
  );
  assert.fieldEquals(
    "PoolProjectSupport",
    poolProjectSupportEntityId,
    "round",
    round.toString()
  );
  assert.fieldEquals(
    "PoolProjectSupport",
    poolProjectSupportEntityId,
    "support",
    delta.toString()
  );

  assert.fieldEquals(
    "PoolProjectParticipantSupport",
    poolProjectParticipantSupportEntityId,
    "poolProjectSupport",
    poolProjectSupportEntityId
  );
  assert.fieldEquals(
    "PoolProjectParticipantSupport",
    poolProjectParticipantSupportEntityId,
    "participant",
    participantAddress.toHexString()
  );
  assert.fieldEquals(
    "PoolProjectParticipantSupport",
    poolProjectParticipantSupportEntityId,
    "support",
    delta.toString()
  );
}

describe("OsmoticPool mappings", () => {
  beforeEach(() => {
    clearStore();
  });

  test("should map ProjectActivated event correctly", () => {
    const projectIndex = BigInt.fromI32(1);
    const osmoticControllerAddress = generateAddress(1);
    const projectRegistryAddress = generateAddress(2);
    const projectActivatedEvent = createProjectActivatedEvent(projectIndex);
    const osmoticPoolAddress = projectActivatedEvent.address;

    prepareMockedRPCCalls(
      osmoticPoolAddress,
      osmoticControllerAddress,
      projectRegistryAddress
    );

    handleProjectActivated(projectActivatedEvent);

    const poolProjectEntityId = buildPoolProjectId(
      buildOsmoticPoolId(osmoticPoolAddress),
      buildProjectId(projectRegistryAddress, projectIndex)
    );

    assert.fieldEquals("PoolProject", poolProjectEntityId, "active", TRUE);
  });

  test("should map ProjectDeactivated event correctly", () => {
    const projectIndex = BigInt.fromI32(1);
    const osmoticControllerAddress = generateAddress(1);
    const projectRegistryAddress = generateAddress(2);
    const projectDeactivatedEvent = createProjectDeactivated(projectIndex);
    const osmoticPoolAddress = projectDeactivatedEvent.address;

    prepareMockedRPCCalls(
      osmoticPoolAddress,
      osmoticControllerAddress,
      projectRegistryAddress
    );

    handleProjectDeactivated(projectDeactivatedEvent);

    const poolProjectEntityId = buildPoolProjectId(
      buildOsmoticPoolId(osmoticPoolAddress),
      buildProjectId(projectRegistryAddress, projectIndex)
    );

    assert.fieldEquals("PoolProject", poolProjectEntityId, "active", FALSE);
  });

  describe("when mapping ProjectSupportUpdated event", () => {
    test("should map an increase in support of a project correctly", () => {
      checkPoolProjectSupportUpdate(BigInt.fromI32(100));
    });

    test("should map a decrease in support of a project correctly", () => {
      checkPoolProjectSupportUpdate(BigInt.fromI32(-100));
    });
  });

  test("should map FlowSynced event correctly", () => {
    const projectIndex = BigInt.fromI32(1);
    const beneficiary = generateAddress(1);
    const osmoticController = generateAddress(2);
    const projectRegistry = generateAddress(3);
    const flowRate = BigInt.fromI32(10000000);

    const flowSyncedEvent = createFlowSynced(
      projectIndex,
      beneficiary.toHexString(),
      flowRate
    );

    const osmoticPool = flowSyncedEvent.address;

    prepareMockedRPCCalls(osmoticPool, osmoticController, projectRegistry);

    handleFlowSynced(flowSyncedEvent);

    const osmoticPoolId = buildOsmoticPoolId(flowSyncedEvent.address);
    const poolProjectEntityId = buildPoolProjectId(
      osmoticPoolId,
      buildProjectId(projectRegistry, projectIndex)
    );

    assert.fieldEquals(
      "PoolProject",
      poolProjectEntityId,
      "flowLastRate",
      flowRate.toString()
    );
    assert.fieldEquals(
      "PoolProject",
      poolProjectEntityId,
      "flowLastTime",
      flowSyncedEvent.block.timestamp.toString()
    );
  });

  test("should map OsmoticParamsChanged event correctly", () => {
    const decay = BigInt.fromI32(1);
    const drop = BigInt.fromI32(2);
    const maxFlow = BigInt.fromI32(3);
    const minStakeRatio = BigInt.fromI32(4);

    const osmoticParamsChangedEvent = createOsmoticParamsChanged(
      decay,
      drop,
      maxFlow,
      minStakeRatio
    );

    handleOsmoticParamsChanged(osmoticParamsChangedEvent);

    const osmoticParamsEntityId = buildOsmoticParamsId(
      osmoticParamsChangedEvent.address
    );

    assert.fieldEquals(
      "OsmoticParams",
      osmoticParamsEntityId,
      "decay",
      decay.toString()
    );
    assert.fieldEquals(
      "OsmoticParams",
      osmoticParamsEntityId,
      "drop",
      drop.toString()
    );
    assert.fieldEquals(
      "OsmoticParams",
      osmoticParamsEntityId,
      "maxFlow",
      maxFlow.toString()
    );
    assert.fieldEquals(
      "OsmoticParams",
      osmoticParamsEntityId,
      "minStakeRatio",
      minStakeRatio.toString()
    );
  });

  test("should map OwnershipTransferred event correctly", () => {
    const previousOwner = generateAddress(1);
    const newOwner = generateAddress(2);
    const ownershipTransferredEvent =
      createOwnershipTransferredEvent<OwnershipTransferred>(
        previousOwner.toHexString(),
        newOwner.toHexString()
      );
    const osmoticPoolAddress = ownershipTransferredEvent.address;

    handleOwnershipTransferred(ownershipTransferredEvent);

    const osmoticPoolEntityId = buildOsmoticPoolId(osmoticPoolAddress);

    assert.fieldEquals(
      "OsmoticPool",
      osmoticPoolEntityId,
      "owner",
      newOwner.toHexString()
    );
  });
});
