import { createContext } from 'react';

type Pool = {
  name: string;
  description: string;
  token: string;
  govToken: string;
  elegibleProjects: string[];
  supporting: number;
  available: number;
  streaming: number;
  streamed: number;
  streams: {
    [key: string]: {
      streamed: number;
      streaming: number;
    }
  }
}

const pools: Pool[] = [
  {
    name: "1Hive",
    description: "1Hive is a community of builders and contributors who are working to build a more sustainable and equitable future for all.",
    token: "HNY",
    govToken: "HNY",
    supporting: 1000,
    available: 7000,
    streaming: 2000,
    streamed: 5000,
    elegibleProjects: ["EVMcrispr", "Gardens", "Quests"],
    streams: {
      "EVMcrispr": {
        "streamed": 1000,
        "streaming": 80
      },
      "Gardens": {
        "streamed": 1000,
        "streaming": 80
      },
      "Quests": {
        "streamed": 1000,
        "streaming": 80
      }
    }
  },
  {
    name: "Aragon",
    description: "Aragon provides the tools and infrastructure to create and manage decentralized organizations.",
    token: "USDC",
    govToken: "ANT",
    supporting: 10000,
    available: 1000000,
    streaming: 20000,
    streamed: 50000,
    elegibleProjects: ["EVMcrispr", "Lodestar", "Bankless DAO"],
    streams: {
      "EVMcrispr": {
        "streamed": 2000,
        "streaming": 8000
      },
      "Lodestar": {
        "streamed": 10000,
        "streaming": 5000
      },
      "Bankless DAO": {
        "streamed": 1000,
        "streaming": 12000
      }
    }
  },
];
export const PoolContext = createContext({ pools });

export const PoolProvider = ({ children }: any) => {
  return (
    <PoolContext.Provider value={{ pools }}>
      {children}
    </PoolContext.Provider>
  );
};
  