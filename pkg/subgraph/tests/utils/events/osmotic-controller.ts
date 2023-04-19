import { newMockEvent } from "matchstick-as";

import {
  MimeTokenCreated as MimeTokenCreatedEvent,
  OsmoticPoolCreated as OsmoticPoolCreatedEvent,
  ProjectListCreated as ProjectListCreatedEvent,
} from "../../../generated/OsmoticController/OsmoticController";
import { getAddressEventParam } from "../converters";

export function createMimeTokenCreatedEvent(
  token: string
): MimeTokenCreatedEvent {
  // @ts-ignore
  const mimeTokenCreatedEvent = changetype<MimeTokenCreatedEvent>(
    newMockEvent()
  );

  mimeTokenCreatedEvent.parameters = new Array();
  mimeTokenCreatedEvent.parameters.push(getAddressEventParam("token", token));

  return mimeTokenCreatedEvent;
}

export function createOsmoticPoolCreatedEvent(
  pool: string
): OsmoticPoolCreatedEvent {
  // @ts-ignore
  const osmoticPoolCreatedEvent = changetype<OsmoticPoolCreatedEvent>(
    newMockEvent()
  );

  osmoticPoolCreatedEvent.parameters = new Array();
  osmoticPoolCreatedEvent.parameters.push(getAddressEventParam("pool", pool));

  return osmoticPoolCreatedEvent;
}

export function createProjectListCreatedEvent(
  list: string
): ProjectListCreatedEvent {
  // @ts-ignore
  const projectListCreatedEvent = changetype<ProjectListCreatedEvent>(
    newMockEvent()
  );

  projectListCreatedEvent.parameters = new Array();
  projectListCreatedEvent.parameters.push(getAddressEventParam("list", list));

  return projectListCreatedEvent;
}
