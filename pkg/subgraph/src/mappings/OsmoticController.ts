import { OsmoticPoolCreated as OsmoticPoolCreatedEvent, OwnershipTransferred as OwnershipTransferredEvent } from "../../generated/OsmoticController/OsmoticController";
import { OsmoticPool } from  "../../generated/templates"
import { loadOrCreateOsmoticController } from "../utils/controller";
import { loadOrCreateOsmoticPool } from "../utils/osmotic-pool";


export function handleOwnershipTransferred(
    event: OwnershipTransferredEvent
  ): void {
    const osmoticController = loadOrCreateOsmoticController(
      event.address
    );
  
    osmoticController.owner = event.params.newOwner;
  
    osmoticController.save();
}

export function handleOsmoticPoolCreated(
    event: OsmoticPoolCreatedEvent
  ): void {
    const osmoticController = loadOrCreateOsmoticController(
        event.address
    );

    const poolAddress = event.params.pool;
    const osmoticPool = loadOrCreateOsmoticPool(poolAddress);

    osmoticController.save();
    osmoticPool.save();

    OsmoticPool.create(poolAddress);
}