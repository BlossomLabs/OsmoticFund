import { Address } from "@graphprotocol/graph-ts";

import { OsmoticController as OsmoticControllerEntity } from "../../generated/schema";
import { ProjectRegistry as ProjectRegistryTemplate } from "../../generated/templates";
import { OsmoticController } from "../../generated/OsmoticController/OsmoticController";

import { formatAddress } from "./ids";
import { loadOrCreateProjectRegistryEntity } from "./project";

export function buildOsmoticControllerId(osmoticController: Address): string {
  return formatAddress(osmoticController);
}

export function loadOrCreateOsmoticController(
  controllerAddress: Address
): OsmoticControllerEntity {
  let id = buildOsmoticControllerId(controllerAddress);
  let osmoticController = OsmoticControllerEntity.load(id);

  if (osmoticController == null) {
    const osmoticContract = OsmoticController.bind(controllerAddress);

    const projectRegistryAddress = osmoticContract.projectRegistry();
    const projectRegistry = loadOrCreateProjectRegistryEntity(
      projectRegistryAddress
    );

    osmoticController = new OsmoticControllerEntity(id);
    osmoticController.owner = osmoticContract.owner();
    osmoticController.version = osmoticContract.version().toI32();
    osmoticController.projectRegistry = projectRegistry.id;
    osmoticController.save();

    ProjectRegistryTemplate.create(projectRegistryAddress);
  }

  return osmoticController;
}
