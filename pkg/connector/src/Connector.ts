import { SubgraphClient } from "./subgraph/SubgraphClient";

type ConnectorOptions = {
  chainId: number;
};

const DEFAULT_CHAIN_ID = 5;

function getSubgraphUrl(chainId: number) {
  switch (chainId) {
    case 5: {
      return "https://api.thegraph.com/subgraphs/name/blossomlabs/osmoticfund-goerli";
    }
    default:
      throw new Error(`Unsupported chain id: ${chainId}`);
  }
}

export class Connector {
  #subgraphClient: SubgraphClient;

  constructor(options?: Partial<ConnectorOptions>) {
    this.#subgraphClient = new SubgraphClient(
      getSubgraphUrl(options?.chainId ?? DEFAULT_CHAIN_ID)
    );
  }
}
