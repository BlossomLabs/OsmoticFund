import {
  Stack,
  Heading,
  Image,
  Text,
  Flex,
  Box,
  Button,
  useBreakpointValue,
} from '@chakra-ui/react'
import { useAccount } from 'wagmi'
import { useSupportList } from '~/hooks/useSupportList'
import { PoolCard } from '../../components/PoolCard'
import TopBar from '../../components/Topbar'
import { usePools } from '~/hooks/usePools'
import { useRouter } from 'next/router'
import { useProjects } from '~/hooks/useProjects'


export const ProjectPage = () => {

  const { addItem } = useSupportList()
  const { pools } = usePools()
  const { projects } = useProjects()

  const router = useRouter()
  const { id } = router.query

  const project = projects.find((project: any) => project.name === id) || {name: null, description: null}
  const streamingPools = pools.filter((pool: any) => Object.keys(pool.streams).find(key => key === id))

  const direction = useBreakpointValue({ base: 'column', md: 'row' });
  const { isConnected } = useAccount();

  const handleAddToSupportList = () => {
    addItem(project.name)
    router.push('/support-list')
  }

  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />
  
      <Stack mt={'0px !important'} width="100%">
        <Image  src={`/img/${project.name}.png`} alt={project.name} height="300px" objectFit="cover" />
      </Stack>
      
      <Stack maxWidth="1200" px="8" mx="auto">
        <Flex direction={direction}>
          <Stack pr="8" mb="16" flex={1}>
            <Heading size="lg">
              {project.name}
            </Heading>

            <Text align="justify">
              {project.description}
            </Text>
          </Stack>
          <Stack>
            <Box mb={10}>
              {isConnected ?
                <>
                  <Text>You can support this proposal</Text>
                  <Button colorScheme="blue" onClick={handleAddToSupportList}>Add to support list</Button>
                </>
                : <Text>You need to connect your wallet to support this proposal</Text>}
            </Box>
            <Heading size="sm">Receiving ~${project.streaming.toLocaleString()}/mo from:</Heading>
            {
              streamingPools.map((pool: any) =>  <PoolCard poolName={pool.name} token={pool.token} streamed={ pool.streams[project.name].streamed} streaming={pool.streams[project.name].streaming} />)
            }
          </Stack>
           
        </Flex>
      </Stack>
    </Stack>
  );
};
  
  
export default ProjectPage;
  