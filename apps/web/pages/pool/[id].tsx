import {
  Stack,
  Heading,
  Image,
  Text,
  Flex,
  useBreakpointValue,
} from '@chakra-ui/react'
import { useRouter } from 'next/router';
import { ProjectCard } from '~/components/ProjectCard'
import { usePools } from '~/hooks/usePools'
import { useProjects } from '~/hooks/useProjects';
import TopBar from '../../components/Topbar'

export const PoolPage = () => {

  const router = useRouter()
  const { id } = router.query
  const direction = useBreakpointValue({ base: 'column', md: 'row' });
  const { pools } = usePools()
  const { projects } = useProjects()
  const pool = pools?.find(pool => pool.name === id) || {name: null, description: null, supporting: 0, govToken: null, elegibleProjects: [], streaming: 0, streamed: 0, token: null, streams: {}, available: 0}
  const elegibleProjects = pool.elegibleProjects?.map((name: string) => projects.find(project => project.name === name)) || []
  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />

      <Stack mt={'0px !important'} width="100%">
        <Image src={`/img/${pool.name}.png`} alt={pool.name} height="300px" objectFit="cover" />
      </Stack>

      <Stack maxWidth="1200" px="8" mx="auto">
        <Flex direction={direction}>
          <Stack pr="8" mb="16" flex={1}>
            <Heading size="lg">
              {pool.name}
            </Heading>

            <Text align="justify">
              {pool.description}
            </Text>
          </Stack>
          <Stack minWidth="300px">
            <Heading size="sm">Governance</Heading>
            <Text>{pool.supporting.toLocaleString()} {pool.govToken} supporting</Text>
            <Heading size="sm">Streaming</Heading>
            <Text>{pool.streaming.toLocaleString()} {pool.token}/mo of {pool.available.toLocaleString()} {pool.token}</Text>
            <Heading size="sm">Total streamed</Heading>
            <Text>{pool.streamed.toLocaleString()} {pool.token}</Text>
          </Stack>
        </Flex>
        <Heading size="md">Elegible Projects</Heading>
        <Stack direction={direction}>
          {elegibleProjects.map((project: any) => <ProjectCard projectName={project.name} description={project.description} streaming={pool.streams[project.name].streaming} streamed={pool.streams[project.name].streamed} />)}
        </Stack>
      </Stack>
    </Stack>
  );
};


export default PoolPage;
