import { Address, Bytes } from "@graphprotocol/graph-ts";
import { OsmoticController as OsmoticControllerEntity } from "../../generated/schema";
import { ZERO_ADDR } from "./ids";

export function buildOsmoticControllerId(osmoticController: Address): string {
  return osmoticController.toHexString();
}

export function loadOrCreateOsmoticController(
    controllerAddress: Address
    ): OsmoticControllerEntity {
    let id = buildOsmoticControllerId(controllerAddress);
    let osmoticController = OsmoticControllerEntity.load(id);
    
    if (osmoticController == null) {
        osmoticController = new OsmoticControllerEntity(id);

        const osmoticContract = OsmoticControllerEntity.bind(controllerAddress);

        osmoticController.owner = Bytes.fromHexString(ZERO_ADDR);
        osmoticController.version = osmoticContract.version();
        osmoticController.projectRegistry = osmoticContract.projectRegistry();

        osmoticController.save();
    }

    return osmoticController;
}