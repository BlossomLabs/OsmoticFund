import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { assert, beforeEach, clearStore, describe, test } from "matchstick-as";

import { buildProjectId } from "../src/utils/project";
import {
  handleOwnershipTransferred,
  handleProjectUpdated,
} from "../src/mappings/ProjectRegistry";
import { alice, bob } from "./utils/constants";
import {
  createProjectUpdatedEvent,
  createOwnershipTransferredEvent,
  stringToBytes,
  mockedVersionRPCCall,
} from "./utils";
import { OwnershipTransferred } from "../generated/templates/ProjectRegistry/ProjectRegistry";

describe("when mapping ProjectRegistry events", () => {
  beforeEach(() => {
    clearStore();
  });

  test("should map OwnershipTransferred correctly", () => {
    const ownershipTransferredEvent =
      createOwnershipTransferredEvent<OwnershipTransferred>(alice, bob);
    const projectRegistryEntityId =
      ownershipTransferredEvent.address.toHexString();

    mockedVersionRPCCall(projectRegistryEntityId, 1);

    handleOwnershipTransferred(ownershipTransferredEvent);

    assert.fieldEquals(
      "ProjectRegistry",
      projectRegistryEntityId,
      "id",
      projectRegistryEntityId
    );
    assert.fieldEquals(
      "ProjectRegistry",
      projectRegistryEntityId,
      "owner",
      bob
    );
  });

  describe("when mapping ProjectUpdated events", () => {
    test("should create a new Project entity correctly if it doesn't exists", () => {
      const projectId = BigInt.fromI32(1);
      const admin = alice;
      const contentHash = Bytes.fromHexString("0x1234");
      const projectUpdatedEvent = createProjectUpdatedEvent(
        projectId,
        admin,
        contentHash,
        bob
      );

      handleProjectUpdated(projectUpdatedEvent);

      const projectEntityId = buildProjectId(
        projectUpdatedEvent.address,
        projectId
      );

      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "id",
        projectEntityId.toString()
      );
      assert.fieldEquals("Project", projectEntityId.toString(), "admin", admin);
      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "contentHash",
        contentHash.toHexString()
      );
      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "beneficiary",
        bob
      );
    });

    test("should update an existing Project entity correctly", () => {
      const projectId = BigInt.fromI32(1);
      const admin = alice;
      const contentHash = Bytes.fromHexString("0x1234");
      const projectUpdatedEvent = createProjectUpdatedEvent(
        projectId,
        admin,
        contentHash,
        bob
      );

      handleProjectUpdated(projectUpdatedEvent);

      const newContentHash = stringToBytes("newContentHash");
      const projectUpdatedEvent2 = createProjectUpdatedEvent(
        projectId,
        admin,
        newContentHash,
        bob
      );

      handleProjectUpdated(projectUpdatedEvent2);

      const projectEntityId = buildProjectId(
        projectUpdatedEvent.address,
        projectId
      );

      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "id",
        projectEntityId.toString()
      );
      assert.fieldEquals("Project", projectEntityId.toString(), "admin", admin);
      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "contentHash",
        newContentHash.toHexString()
      );
      assert.fieldEquals(
        "Project",
        projectEntityId.toString(),
        "beneficiary",
        bob
      );
    });
  });
});
