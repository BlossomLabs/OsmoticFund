import { createContext, useState } from 'react';

export type Project = {
  name: string;
  description: string;
  streaming: number;
  streamed: number;
  elegiblePools: string[];
  address: string;
  url: string;
  twitter: string;
  gitcoin: string;
}

const projects: Project[] = [
  {
    name: "EVMcrispr",
    description: "EVMcrispr is a tool that simplifies interacting with smart contracts on EVM-compatible chains.",
    streaming: 2000,
    streamed: 5000,
    elegiblePools: ["1Hive", "Aragon"],
    address: "0x0035cC37599241D007D0AbA1Fb931C5FA757f7A1",
    url: "https://evmcrispr.eth.limo/",
    twitter: "https://twitter.com/blossomlabs",
    gitcoin: "https://gitcoin.co/grants/4502/evmcrispr",
  },
  {
    name: "Quests",
    description: "Quests is a Celeste enabled incentivised bounty platform allowing users or organisations to publish bounties for work which anyone can claim by providing evidence of completion.",
    streaming: 300,
    streamed: 500,
    elegiblePools: ["1Hive"],
    address: "0x9116248D38aF8b535723Db13cBF3E18307665b1c",
    url: "https://quests.1hive.org/",
    twitter: "https://twitter.com/1HiveOrg",
    gitcoin: "https://gitcoin.co/grants/5050/1hivequests",
  },
  {
    name: "Gardens",
    description: "1Hive Gardens are secure digital economies run by the community members that make them valuable.",
    streaming: 1000,
    streamed: 2000,
    elegiblePools: ["1Hive"],
    address: "0x1aD44446A588010AB6b741cd0201b92f84B597bB",
    url: "https://gardens.1hive.org/",
    twitter: "https://twitter.com/1HiveOrg",
    gitcoin: "https://gitcoin.co/grants/5070/1hive-gardens",
  },
  {
    name: "Lodestar",
    description: "Lodestar is a community of developers and researchers building a decentralized, scalable, and interoperable Ethereum 2.0 client.",
    streaming: 20000,
    streamed: 20000,
    elegiblePools: ["Aragon"],
    address: "0xc8F9f8C913d6fF031c65e3bF7c7a51Ad1f3a86E5",
    url: "https://lodestar.chainsafe.io/",
    twitter: "https://twitter.com/lodestar_eth",
    gitcoin: "https://bounties.gitcoin.co/grants/6034/lodestar-typescript-ethereum-consensus-client",
  },
  {
    name: "Bankless DAO",
    description: "Bankless is a community of crypto enthusiasts who believe that the best way to build a better future is to build it together.",
    streaming: 10000,
    streamed: 10000,
    elegiblePools: ["Aragon"],
    address: "0xf26d1Bb347a59F6C283C53156519cC1B1ABacA51",
    url: "https://bankless.community/",
    twitter: "https://twitter.com/banklessDAO",
    gitcoin: "https://bounties.gitcoin.co/grants/7393/banklessdao-projects"
  }
];
export const ProjectContext = createContext({ projects });

export const ProjectProvider = ({ children }: any) => {
  return (
    <ProjectContext.Provider value={{ projects }}>
      {children}
    </ProjectContext.Provider>
  );
};
