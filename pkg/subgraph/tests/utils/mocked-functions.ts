import { Address } from "@graphprotocol/graph-ts";
import { createMockedFunction } from "matchstick-as";

import { getETHAddress, getETHInt32, getETHString } from "./converters";

export function mockedTokenRPCCalls(
  address: string,
  // @ts-ignore
  decimals: i32,
  name: string,
  symbol: string
): void {
  mockedTokenDecimals(address, decimals);
  mockedTokenName(address, name);
  mockedTokenSymbol(address, symbol);
}

/**
 * Creates a mocked token.name() function
 * @param tokenAddress
 * @param expectedName
 */
export function mockedTokenName(
  tokenAddress: string,
  expectedName: string
): void {
  createMockedFunction(
    Address.fromString(tokenAddress),
    "name",
    "name():(string)"
  )
    .withArgs([])
    .returns([getETHString(expectedName)]);
}

/**
 * Creates a mocked token.symbol() function
 * @param tokenAddress
 * @param expectedSymbol
 */
export function mockedTokenSymbol(
  tokenAddress: string,
  expectedSymbol: string
): void {
  createMockedFunction(
    Address.fromString(tokenAddress),
    "symbol",
    "symbol():(string)"
  )
    .withArgs([])
    .returns([getETHString(expectedSymbol)]);
}

/**
 * Creates a mocked token.decimals() function
 * @param tokenAddress
 * @param expectedDecimals
 */
export function mockedTokenDecimals(
  tokenAddress: string,
  // @ts-ignore
  expectedDecimals: i32
): void {
  createMockedFunction(
    Address.fromString(tokenAddress),
    "decimals",
    "decimals():(uint8)"
  )
    .withArgs([])
    .returns([getETHInt32(expectedDecimals)]);
}

export function mockedProjectListNameRPCCall(
  projectList: string,
  expectedName: string
): void {
  createMockedFunction(
    Address.fromString(projectList),
    "name",
    "name():(string)"
  )
    .withArgs([])
    .returns([getETHString(expectedName)]);
}

export function mockedVersionRPCCall(
  contractAddress: string,
  // @ts-ignore
  expectedVersion: i32
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "version",
    "version():(uint256)"
  )
    .withArgs([])
    .returns([getETHInt32(expectedVersion)]);
}

export function mockedProjectRegistryRPCCall(
  contractAddress: string,
  expectedProjectRegistryAddress: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "projectRegistry",
    "projectRegistry():(address)"
  )
    .withArgs([])
    .returns([getETHAddress(expectedProjectRegistryAddress)]);
}

export function mockedOsmoticControllerRPCCall(
  contractAddress: string,
  expectedControllerAddress: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "controller",
    "controller():(address)"
  )
    .withArgs([])
    .returns([getETHAddress(expectedControllerAddress)]);
}

export function mockedMaxActiveProjectsRPCCall(
  contractAddress: string,
  // @ts-ignore
  expectedMaxActiveProjects: i32
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "MAX_ACTIVE_PROJECTS",
    "MAX_ACTIVE_PROJECTS():(uint8)"
  )
    .withArgs([])
    .returns([getETHInt32(expectedMaxActiveProjects)]);
}

export function mockedMimeTokenRPCCall(
  contractAddress: string,
  expectedMimeTokenAddress: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "mimeToken",
    "mimeToken():(address)"
  )
    .withArgs([])
    .returns([getETHAddress(expectedMimeTokenAddress)]);
}

export function mockedFundingTokenRPCCall(
  contractAddress: string,
  expectedFundingTokenAddress: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "fundingToken",
    "fundingToken():(address)"
  )
    .withArgs([])
    .returns([getETHAddress(expectedFundingTokenAddress)]);
}

export function mockedProjectListRPCCall(
  contractAddress: string,
  expectedProjectListAddress: string
): void {
  createMockedFunction(
    Address.fromString(contractAddress),
    "projectList",
    "projectList():(address)"
  )
    .withArgs([])
    .returns([getETHAddress(expectedProjectListAddress)]);
}
