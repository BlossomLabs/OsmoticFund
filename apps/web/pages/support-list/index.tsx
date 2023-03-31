import {
  Stack,
  Heading,
  Text,
  Table,
  Thead,
  Tbody,
  Tr,
  Td,
  Th,
  Slider,
  SliderTrack,
  SliderFilledTrack,
  SliderThumb,
  IconButton
} from '@chakra-ui/react'
import { BsTrashFill } from 'react-icons/bs'
import { useProjects } from '~/hooks/useProjects'
import { useSupportList } from '~/hooks/useSupportList'
import TopBar from '../../components/Topbar'
  
type SupportListPage = {
    id: string
}

export const SupportListPage = () => {

  const { supportList, removeItem } = useSupportList()
  const { projects } = useProjects()

  const supportedProjects = supportList.map((projectName: string) => {
    return projects.find(project => project.name === projectName)
  })

  const handleSupportListRemove = (projectName: string) => () => {
    removeItem(projectName)
  }

  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />      
      <Stack maxWidth="1200" px="8" mx="auto">
        <Heading size="lg">
          My support list
        </Heading>
        <Text>You can give support to multiple projects at the same time</Text>
        <Table>
          <Thead>
            <Tr>
              <Th>Project</Th>
              <Th>Pool</Th>
              <Th>Amount</Th>
              <Th>Remove</Th>
            </Tr>
          </Thead>
          <Tbody>
            {supportedProjects.map((project: any) => (
              <Tr>
                <Td>{project.name}</Td>
                <Td>{project.elegiblePools.map(pool => <Text>{pool}</Text>)}</Td>
                <Td>{project.elegiblePools.map(pool => <SupportSlider />)}</Td>
                <Td><IconButton onClick={handleSupportListRemove(project.name)} colorScheme="red" aria-label="Remove" icon={<BsTrashFill />} size="xs" /></Td>
              </Tr>
            ))}
          </Tbody>
        </Table>
      </Stack>
    </Stack>
  );
};
  
const SupportSlider = () => {
  return (
    <Slider aria-label='slider-ex-1' defaultValue={30}>
      <SliderTrack>
        <SliderFilledTrack />
      </SliderTrack>
      <SliderThumb />
    </Slider>
  )
}
        
export default SupportListPage;
  