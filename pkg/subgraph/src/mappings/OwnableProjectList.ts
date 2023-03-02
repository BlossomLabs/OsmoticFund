import { ListUpdated as ListUpdatedEvent, OwnershipTransferred as OwnershipTransferredEvent } from '../../generated/templates/OwnableProjectList/OwnableProjectList'
import { loadOrCreateProjectListEntity, loadOrCreateProjectProjectListEntity } from '../utils/project'
import { store } from '@graphprotocol/graph-ts'

export function handleListUpdated(event : ListUpdatedEvent): void {
  const projectList = loadOrCreateProjectProjectListEntity(event.address, event.params.projectId)

  if (!event.params.included) {
    store.remove('ProjectProjectListEntity', projectList.id)
  }
}

export function handleOwnershipTransferred(event: OwnershipTransferredEvent): void {
  const projectList = loadOrCreateProjectListEntity(event.address)

  projectList.owner = event.params.newOwner
}
