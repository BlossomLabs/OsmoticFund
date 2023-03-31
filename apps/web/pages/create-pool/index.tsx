import {
  Stack,
  Heading,
  Text,
  Box,
  Button,
  FormControl,
  FormLabel,
  Input,
  Textarea,
  Select,
  Slider,
  SliderTrack,
  SliderFilledTrack,
  SliderThumb,
  VStack,
} from '@chakra-ui/react'
import TopBar from '../../components/Topbar'
  
type CreatePoolPage = {
    id: string
}

export const CreatePoolPage = ({id}: CreatePoolPage) => {

  const handleSubmit = (e) => {
    e.preventDefault();
    // Handle form submission
  };

  return (
    <Stack justify="center" align="center" spacing="30px">
      <TopBar />      
      <Stack maxWidth="1200" px="8" mx="auto">
        <Heading size="lg">
          Create new Pool
        </Heading>
        <Text>You can give support to multiple projects at the same time</Text>
        <Box as="form" onSubmit={handleSubmit} w="full">
          <VStack spacing={4}>
            <FormControl id="pool-name">
              <FormLabel>Pool name</FormLabel>
              <Input
                type="text"
                placeholder="Which is your organization?"
              />
            </FormControl>

            <FormControl id="pool-image">
              <FormLabel>Pool image</FormLabel>
              <Input type="file" />
            </FormControl>

            <FormControl id="pool-description">
              <FormLabel>Pool description</FormLabel>
              <Textarea
                placeholder="What projects are you targeting? Why should they receive money from this pool?"
              />
            </FormControl>

            <FormControl id="governance-token">
              <FormLabel>Governance token</FormLabel>
              <Select placeholder="Select a governance token">
                {/* Add governance token options here */}
              </Select>
            </FormControl>

            <FormControl id="minimum-stake">
              <FormLabel>Minimum Stake</FormLabel>
              <Slider defaultValue={0} min={0} max={20} step={1}>
                <SliderTrack>
                  <SliderFilledTrack />
                </SliderTrack>
                <SliderThumb />
              </Slider>
            </FormControl>

            <FormControl id="funding-token">
              <FormLabel>Funding token</FormLabel>
              <Select placeholder="Select a funding token">
                {/* Add funding token options here */}
              </Select>
            </FormControl>

            <FormControl id="max-streaming-per-month">
              <FormLabel>Max streaming per month</FormLabel>
              <Input
                type="text"
                placeholder="Examples: 20000 or 4%"
              />
            </FormControl>

            <Button type="submit" colorScheme="blue">
          Submit
            </Button>
          </VStack>
        </Box>
      </Stack>
    </Stack>
  );
};
        
export default CreatePoolPage;
  