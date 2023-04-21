import { getDefaultWallets } from "@rainbow-me/rainbowkit";
import { Client } from "wagmi";
import { configureChains, createClient } from "wagmi";
import { goerli, optimism } from "wagmi/chains";
import { publicProvider } from "wagmi/providers/public";

const { chains, provider, webSocketProvider } = configureChains(
  [optimism, goerli],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: "My wagmi + RainbowKit App",
  chains,
});

/**
 * Overlook the line below; removing the client type leads to a TS2742 error(the inferred type of 'client'
 * can't be named without referencing it). and there is no way around it at the moment.
 */
// @ts-ignore
const client: Client = createClient({
  autoConnect: true,
  connectors,
  provider,
  webSocketProvider,
});

export { client, chains };
