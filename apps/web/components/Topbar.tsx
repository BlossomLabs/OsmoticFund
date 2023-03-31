import React from "react";
import { Box, Heading, HStack, Spacer, Link as ChakraLink, useBreakpointValue } from "@chakra-ui/react";
import Link from 'next/link';
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useSupportList } from "~/hooks/useSupportList";
import { useAccount } from "wagmi";

const TopBar = () => {
  const { isConnected } = useAccount()
  const { supportList } = useSupportList()
  const linkSpacing = useBreakpointValue({ base: 2, md: 4 });

  return (
    <Box w="100%" h="16" borderBottom="1px">
      <HStack alignItems="center" justifyContent="space-between" h="100%" maxW="1200" px="8" mx="auto" spacing={linkSpacing}>
        <Heading as="h1" size="sm">
          <Link href="/" passHref>
            <ChakraLink>osmotic.fund</ChakraLink>
          </Link>
        </Heading>
        
        <Spacer />
        
        {isConnected && (
          <>
            <Link href="/support-list" passHref>
              <ChakraLink>My support list ({supportList?.length})</ChakraLink>
            </Link>
            <Link href="/create-pool" passHref>
              <ChakraLink>Create new pool</ChakraLink>
            </Link>
          </>
        )}
        <Box pl="3"><ConnectButton /></Box>
      </HStack>
    </Box>
  );
};

export default TopBar;
