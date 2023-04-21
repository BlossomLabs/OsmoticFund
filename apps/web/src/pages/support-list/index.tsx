// TODO: fix
// @ts-nocheck
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
  HStack,
  Button,
  useColorModeValue,
} from "@chakra-ui/react";
import { useState } from "react";
import { BsTrashFill, BsLockFill, BsUnlockFill } from "react-icons/bs";
import { useProjects } from "~/hooks/useProjects";
import { useSupportList } from "~/hooks/useSupportList";
import { Project } from "~/providers/ProjectProvider";
import TopBar from "../../components/Topbar";

type SupportListPage = {
  id: string;
};

export const SupportListPage = () => {
  const { supportList, removeItem } = useSupportList();
  const { projects } = useProjects();

  const supportedProjects = supportList.map((projectName: string) => {
    return projects.find((project) => project.name === projectName);
  });

  const [lockedSliders, setLockedSliders] = useState<Record<string, boolean>>(
    () => {
      const initialState: Record<string, boolean> = {};
      supportedProjects.forEach((project) => {
        project.elegiblePools.forEach((pool) => {
          initialState[`${project.name}_${pool}`] = false;
        });
      });
      return initialState;
    }
  );

  const handleLockToggle = (projectName: string, pool: string) => () => {
    setLockedSliders({
      ...lockedSliders,
      [`${projectName}_${pool}`]: !lockedSliders[`${projectName}_${pool}`],
    });
  };

  const colors = [
    "blue.500",
    "red.500",
    "yellow.500",
    "green.500",
    "purple.500",
    "pink.500",
  ];

  let colorsIndex = 0;

  const poolColors = projects.reduce((acc: any, project: any) => {
    project.elegiblePools.forEach((pool: string) => {
      if (!acc[pool]) {
        acc[pool] = colors[colorsIndex];
        colorsIndex++;
      }
    });
    return acc;
  }, {});

  const handleSupportListRemove = (projectName: string) => () => {
    removeItem(projectName);
  };

  const [sliderValues, setSliderValues] = useState<Record<string, number>>(
    () => {
      const initialState: Record<string, number> = {};
      supportedProjects.forEach((project) => {
        project.elegiblePools.forEach((pool) => {
          initialState[`${project.name}_${pool}`] = 0;
        });
      });
      return initialState;
    }
  );

  const handleEvenDistribution = () => {
    const updatedSliderValues = { ...sliderValues };

    Object.keys(poolColors).forEach((pool) => {
      const projectsInPool = supportedProjects.filter((project: any) =>
        project.elegiblePools.includes(pool)
      );

      // Get the unlocked sliders for this pool
      const unlockedProjectsInPool = projectsInPool.filter(
        (project: Project) => !lockedSliders[`${project.name}_${pool}`]
      );

      const lockedProjectsInPool = projectsInPool.filter(
        (project: Project) => lockedSliders[`${project.name}_${pool}`]
      );

      const totalLockedValueInPool = lockedProjectsInPool.reduce(
        (acc, project: Project) =>
          acc + sliderValues[`${project.name}_${pool}`],
        0
      );

      // Calculate the new value for unlocked sliders
      const evenValueForUnlockedSliders =
        (100 - totalLockedValueInPool) / unlockedProjectsInPool.length;

      // Update the unlocked sliders with the new value
      unlockedProjectsInPool.forEach((project: any) => {
        updatedSliderValues[`${project.name}_${pool}`] =
          evenValueForUnlockedSliders;
      });
    });

    setSliderValues(updatedSliderValues);
  };

  const handleSliderChange =
    (projectName: string, pool: string) => (newValue: number) => {
      const otherSliderEntries = Object.entries(sliderValues).filter(
        ([key, _]) => {
          const [_projectName, _pool] = key.split("_");
          return _projectName !== projectName && _pool === pool;
        }
      );

      const totalValueInOtherSliders = otherSliderEntries.reduce(
        (acc, [_, value]) => acc + value,
        0
      );

      if (totalValueInOtherSliders + newValue <= 100) {
        setSliderValues({
          ...sliderValues,
          [`${projectName}_${pool}`]: newValue,
        });
        setLockedSliders({
          ...lockedSliders,
          [`${projectName}_${pool}`]: true,
        });
        return;
      }

      const unlockedOtherSliderEntries = otherSliderEntries.filter(
        ([key, _]) => !lockedSliders[key]
      );

      const lockedOtherSliderEntries = otherSliderEntries.filter(
        ([key, _]) => lockedSliders[key]
      );

      const totalLockedValueInOtherSliders = lockedOtherSliderEntries.reduce(
        (acc, [_, value]) => acc + value,
        0
      );

      const totalUnlockedValueInOtherSliders =
        unlockedOtherSliderEntries.reduce((acc, [_, value]) => acc + value, 0);

      const maxValueForCurrentSlider = 100 - totalLockedValueInOtherSliders;

      if (newValue > maxValueForCurrentSlider) {
        newValue = maxValueForCurrentSlider;
      }

      const valueToDistributeAmongUnlockedSliders =
        100 - newValue - totalLockedValueInOtherSliders;

      const updatedSliderValues = { ...sliderValues };

      const ratio =
        valueToDistributeAmongUnlockedSliders /
        totalUnlockedValueInOtherSliders;

      unlockedOtherSliderEntries.forEach(([key, _]) => {
        updatedSliderValues[key] *= ratio;
      });

      updatedSliderValues[`${projectName}_${pool}`] = newValue;

      setSliderValues(updatedSliderValues);
      setLockedSliders({
        ...lockedSliders,
        [`${projectName}_${pool}`]: true,
      });
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
              <Tr key={project.name}>
                <Td>{project.name}</Td>
                <Td>
                  {project.elegiblePools.map((pool) => (
                    <Text key={pool}>{pool}</Text>
                  ))}
                </Td>
                <Td width="300px">
                  {project.elegiblePools.map((pool) => (
                    <HStack key={pool}>
                      <SupportSlider
                        color={poolColors[pool]}
                        value={sliderValues[`${project.name}_${pool}`]}
                        onChange={handleSliderChange(project.name, pool)}
                      />
                      <IconButton
                        size="xs"
                        onClick={handleLockToggle(project.name, pool)}
                        icon={
                          lockedSliders[`${project.name}_${pool}`] ? (
                            <BsLockFill />
                          ) : (
                            <BsUnlockFill />
                          )
                        }
                        color={
                          lockedSliders[`${project.name}_${pool}`]
                            ? "blue.500"
                            : "grey"
                        }
                        aria-label="Lock slider"
                      />
                    </HStack>
                  ))}
                </Td>
                <Td>
                  <IconButton
                    onClick={handleSupportListRemove(project.name)}
                    colorScheme="red"
                    aria-label="Remove"
                    icon={<BsTrashFill />}
                    size="xs"
                  />
                </Td>
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

type SupportSlider = {
  color: string;
  value?: number;
  onChange?: any;
};

const SupportSlider = ({ color, value, onChange }: SupportSlider) => {
  const thumbBg = useColorModeValue("white", "gray.800");

  return (
    <Slider value={value} onChange={onChange}>
      <SliderTrack>
        <SliderFilledTrack bg={color} />
      </SliderTrack>
      <SliderThumb
        boxSize={2}
        bg={thumbBg}
        borderColor={color}
        borderWidth={1}
      />
    </Slider>
  );
};

export default SupportListPage;
