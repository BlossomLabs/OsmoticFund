import { createContext, useState } from 'react';

export type Project = {
  name: string;
  description: string;
  streaming: number;
  streamed: number;
  elegiblePools: string[];
}

const projects: Project[] = [
  {
    name: "EVMcrispr",
    description: "EVMcrispr is a tool that simplifies interacting with smart contracts on EVM-compatible chains.",
    streaming: 2000,
    streamed: 5000,
    elegiblePools: ["1Hive", "Aragon"],
  },
  {
    name: "Quests",
    description: "Quests is a Celeste enabled incentivised bounty platform allowing users or organisations to publish bounties for work which anyone can claim by providing evidence of completion.",
    streaming: 300,
    streamed: 500,
    elegiblePools: ["1Hive"],
  },
  {
    name: "Gardens",
    description: "1Hive Gardens are secure digital economies run by the community members that make them valuable.",
    streaming: 1000,
    streamed: 2000,
    elegiblePools: ["1Hive"],
  },
  {
    name: "Lodestar",
    description: "Lodestar is a community of developers and researchers building a decentralized, scalable, and interoperable Ethereum 2.0 client.",
    streaming: 20000,
    streamed: 20000,
    elegiblePools: ["Aragon"],
  },
  {
    name: "Bankless DAO",
    description: "Bankless is a community of crypto enthusiasts who believe that the best way to build a better future is to build it together.",
    streaming: 10000,
    streamed: 10000,
    elegiblePools: ["Aragon"],
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
  