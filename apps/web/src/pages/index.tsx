import {
  Stack,
  Heading,
  useBreakpointValue,
  Flex,
  StackDirection,
} from "@chakra-ui/react";
import { usePools } from "~/hooks/usePools";
import { useProjects } from "~/hooks/useProjects";
import { PoolCard } from "../components/PoolCard";
import { ProjectCard } from "../components/ProjectCard";
import TopBar from "../components/Topbar";

export const Home = () => {
  const direction = useBreakpointValue<StackDirection>({
    base: "column",
    md: "row",
  });
  const { projects } = useProjects();
  const { pools } = usePools();
  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />

      <Stack maxWidth="1200" px={8} mx={"auto"} width="100%">
        <Heading size="lg">Available Pools</Heading>
        <Stack direction={direction} spacing="10px">
          {pools.slice(0, 3).map((pool: any) => (
            <PoolCard
              poolName={pool.name}
              token={pool.token}
              streamed={pool.streamed}
              streaming={pool.streaming}
            />
          ))}
        </Stack>
        <Heading size="lg">Active Projects</Heading>
        <Stack direction={direction}>
          {projects.slice(0, 3).map((project) => (
            <ProjectCard
              projectName={project.name}
              description={project.description}
              streaming={project.streaming}
              streamed={project.streamed}
            />
          ))}
        </Stack>
      </Stack>
    </Stack>
  );
};

export default Home;
