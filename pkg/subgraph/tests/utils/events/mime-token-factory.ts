import { newMockEvent } from 'matchstick-as'

import { MimeTokenCreated as MimeTokenCreatedEvent } from "../../../generated/MimeTokenFactory@0.0.1/MimeTokenFactory";
import { getAddressEventParam } from '../converters'

export function createMimeTokenCreatedEvent(token: string): MimeTokenCreatedEvent {
  // @ts-ignore
  const mimeTokenCreatedEvent = changetype<MimeTokenCreatedEvent>(newMockEvent())
  
  mimeTokenCreatedEvent.parameters = new Array()
  mimeTokenCreatedEvent.parameters.push(getAddressEventParam('token', token))

  return mimeTokenCreatedEvent
}
