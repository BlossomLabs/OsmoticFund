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
  IconButton,
  Button,
  useColorModeValue,
} from '@chakra-ui/react'
import { useState } from 'react'
import { BsTrashFill } from 'react-icons/bs'
import { useProjects } from '~/hooks/useProjects'
import { useSupportList } from '~/hooks/useSupportList'
import { Project } from '~/providers/ProjectProvider'
import TopBar from '../../components/Topbar'
  
type SupportListPage = {
    id: string
}

export const SupportListPage = () => {

  const { supportList, removeItem } = useSupportList()
  const { projects } = useProjects()

  const supportedProjects: Project[] = supportList.map((projectName: string) => {
    return projects.find(project => project.name === projectName)
  })

  const colors = [
    'blue.500',
    'red.500',
    'yellow.500',
    'green.500',
    'purple.500',
    'pink.500',
  ]

  let colorsIndex = 0

  const poolColors = projects.reduce((acc: any, project: any) => {
    project.elegiblePools.forEach((pool: string) => {
      if (!acc[pool]) {
        acc[pool] = colors[colorsIndex]
        colorsIndex++
      }
    })
    return acc
  }, {})

  const handleSupportListRemove = (projectName: string) => () => {
    removeItem(projectName)
  }

  const [sliderValues, setSliderValues] = useState<Record<string, number>>(() => {
    const initialState: Record<string, number> = {};
    supportedProjects.forEach((project) => {
      project.elegiblePools.forEach((pool) => {
        initialState[`${project.name}_${pool}`] = 0;
      });
    });
    return initialState;
  });

  const handleEvenDistribution = () => {
    const updatedSliderValues = { ...sliderValues };

    Object.keys(poolColors).forEach((pool) => {
      const projectsWithColor = supportedProjects.filter((project: any) =>
        project.elegiblePools.includes(pool)
      );

      const newValue = 100 / projectsWithColor.length;

      projectsWithColor.forEach((project: any) => {
        updatedSliderValues[`${project.name}_${pool}`] = newValue;
      });
    });

    setSliderValues(updatedSliderValues);
  };

  const handleSliderChange = (projectName: string, pool: string) => (
    value: number
  ) => {
    const updatedSliderValues = {
      ...sliderValues,
      [`${projectName}_${pool}`]: value,
    };

    const totalValueForColor = Object.entries(updatedSliderValues).reduce(
      (acc, [key, value]) => {
        const [_projectName, _pool] = key.split("_");
        if (_pool === pool) {
          return acc + value;
        }
        return acc;
      },
      0
    );

    if (totalValueForColor > 100) {
      const ratio = 100 / totalValueForColor;

      for (const key in updatedSliderValues) {
        const [_projectName, _pool] = key.split("_");
        if (_pool === pool) {
          updatedSliderValues[key] *= ratio;
        }
      }
    }

    setSliderValues(updatedSliderValues);
  };
  if (!supportedProjects.length) {
    return (
      <Stack justify="center" align="center" spacing="30px">
        <TopBar />
        <Stack maxWidth="1200" px="8" mx="auto">
          <Heading size="lg">My Support List</Heading>
          <Text>There are no projects in your support list yet.</Text>
        </Stack>
      </Stack>
    );
  }

  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />
      <Stack maxWidth="1200" px="8" mx="auto">
        <Heading size="lg">My Support List</Heading>
        <Text>Allocate support to multiple projects simultaneously.</Text>
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
                <Td>{project.elegiblePools.map(pool => (
                  <SupportSlider
                    color={poolColors[pool]}
                    value={sliderValues[`${project.name}_${pool}`]}
                    onChange={handleSliderChange(project.name, pool)}
                  />
                ))}</Td>
                <Td><IconButton onClick={handleSupportListRemove(project.name)} colorScheme="red" aria-label="Remove" icon={<BsTrashFill />} size="xs" /></Td>
              </Tr>
            ))}
          </Tbody>
        </Table>
        <Button
          variant="outline"
          colorScheme="blue"
          size="sm"
          onClick={handleEvenDistribution}
          mb={4}
        >
          Distribute Evenly
        </Button>
        <Button colorScheme="blue" size="sm">
          Support Projects
        </Button>
      </Stack>
    </Stack>
  );
};

type SupportSlider =  {
  color: string
  value?: number
  onChange?: any
}
  
const SupportSlider = ({ color, value, onChange }: SupportSlider) => {
  const thumbBg = useColorModeValue("white", "gray.800");

  return (
    <Slider
      value={value}
      onChange={onChange}
    >
      <SliderTrack>
        <SliderFilledTrack bg={color} />
      </SliderTrack>
      <SliderThumb boxSize={2} bg={thumbBg} borderColor={color} borderWidth={1} />
    </Slider>
  );
};
        
export default SupportListPage;
  