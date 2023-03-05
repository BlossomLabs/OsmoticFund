import { MimeTokenCreated as MimeTokenCreatedEvent } from "../../generated/MimeTokenFactory@0.0.1/MimeTokenFactory";
import { MimeToken as MimeTokenContract } from "../../generated/MimeTokenFactory@0.0.1/MimeToken";
import { loadOrCreateTokenEntity } from "../utils/token";

export function handleMimeTokenCreated(event: MimeTokenCreatedEvent): void {
  const token = loadOrCreateTokenEntity(event.params.token);
  const tokenContract = MimeTokenContract.bind(event.params.token);

  token.name = tokenContract.name();
  token.symbol = tokenContract.symbol();
  token.decimals = tokenContract.decimals();

  token.save();
}
