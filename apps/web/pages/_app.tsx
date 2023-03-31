import "@rainbow-me/rainbowkit/styles.css";
import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import type { AppProps } from "next/app";
import NextHead from "next/head";
import * as React from "react";
import { WagmiConfig } from "wagmi";

import { chains, client } from "../wagmi";
import { ChakraProvider, CSSReset } from "@chakra-ui/react";
import { SupportListProvider } from "~/providers/SupportListProvider";
import { PoolProvider } from "~/providers/PoolProvider";
import { ProjectProvider } from "~/providers/ProjectProvider";

function App({ Component, pageProps }: AppProps) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => setMounted(true), []);
  return (
    <WagmiConfig client={client}>
      <ChakraProvider>
        <CSSReset />
        <RainbowKitProvider chains={chains}>
          <SupportListProvider>
            <ProjectProvider>
              <PoolProvider>
                <NextHead>
                  <title>Osmotic Fund</title>
                </NextHead>

                {mounted && <Component {...pageProps} />}
              </PoolProvider>
            </ProjectProvider>
          </SupportListProvider>
        </RainbowKitProvider>
      </ChakraProvider>
    </WagmiConfig>
  );
}

export default App;
