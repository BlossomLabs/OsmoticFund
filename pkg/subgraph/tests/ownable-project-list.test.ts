import { Address, BigInt } from "@graphprotocol/graph-ts";
import { assert, beforeEach, clearStore, describe, test } from "matchstick-as";
import { ProjectProjectList as ProjectProjectListEntity } from "../generated/schema";

import { OwnershipTransferred } from "../generated/templates/OwnableProjectList/OwnableProjectList";
import {
  handleListUpdated,
  handleOwnershipTransferred,
} from "../src/mappings/OwnableProjectList";
import {
  buildProjectId,
  buildProjectListId,
  buildProjectProjectListId,
} from "../src/utils/project";
import {
  alice,
  bob,
  createOwnershipTransferredEvent,
  mockedProjectRegistryRPCCall,
} from "./utils";
import { createListUpdatedEvent } from "./utils/events/project-list";

describe("OwnableProjectList mappings", () => {
  beforeEach(() => {
    clearStore();
  });

  test("should map OwnershipTransferred event correctly", () => {
    const ownershipTransferredEvent =
      createOwnershipTransferredEvent<OwnershipTransferred>(alice, bob);

    handleOwnershipTransferred(ownershipTransferredEvent);

    const projectListEntityId = ownershipTransferredEvent.address.toHexString();

    assert.fieldEquals(
      "ProjectList",
      projectListEntityId,
      "id",
      projectListEntityId
    );
    assert.fieldEquals("ProjectList", projectListEntityId, "owner", bob);
  });

  describe("when mapping ListUpdated event", () => {
    test("should create a new ProjectProjectList entity when including a new project", () => {
      const projectId = BigInt.fromI32(1);
      const projectRegistry = Address.fromString(
        "0xefb99a616f92b2dfc5436408df0850473e9d5823"
      );

      const listUpdatedEvent = createListUpdatedEvent(projectId, true);
      const projectListAddress = listUpdatedEvent.address;

      mockedProjectRegistryRPCCall(
        projectListAddress.toHexString(),
        projectRegistry.toHexString()
      );

      handleListUpdated(listUpdatedEvent);

      const projectProjectListId = buildProjectProjectListId(
        projectRegistry,
        projectId,
        projectListAddress
      );

      assert.fieldEquals(
        "ProjectProjectList",
        projectProjectListId,
        "id",
        projectProjectListId
      );
    });

    test("should delete the corresponding ProjectProjectList entity when removing a project", () => {
      const projectId = BigInt.fromI32(1);
      const projectRegistry = Address.fromString(
        "0xefb99a616f92b2dfc5436408df0850473e9d5823"
      );
      const listUpdatedEvent = createListUpdatedEvent(projectId, false);
      const projectListAddress = listUpdatedEvent.address;
      const projectProjectListId = buildProjectProjectListId(
        projectRegistry,
        projectId,
        projectListAddress
      );

      const projectProjectList = new ProjectProjectListEntity(
        projectProjectListId
      );
      projectProjectList.project = buildProjectId(projectRegistry, projectId);
      projectProjectList.projectList = buildProjectListId(projectListAddress);

      projectProjectList.save();

      mockedProjectRegistryRPCCall(
        projectListAddress.toHexString(),
        projectRegistry.toHexString()
      );

      handleListUpdated(listUpdatedEvent);

      assert.notInStore("ProjectProjectList", projectProjectListId);
    });
  });
});
