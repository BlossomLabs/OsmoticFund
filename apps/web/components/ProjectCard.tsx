import { Box, Card, Image, Stack, Text, Heading, Flex, Spacer } from '@chakra-ui/react'
import Link from 'next/link'

type ProjectCard = {
    projectName: string
    description: string
    streaming: number
    streamed: number
}

export const ProjectCard = ({projectName, description, streaming, streamed}: ProjectCard) => {
  return (
    <Stack maxWidth="100%" minWidth="33%">
      <Card variant="outline">
        <Stack
          minHeight="300px"
          maxWidth="100%"
        >
          <Box>
            <Link href={`/project/${projectName}`}>
              <Image
                src={`/img/${projectName}.png`}
                alt={projectName}
                height="166px"
                width="100%"
                objectFit="cover"
              />
            </Link>
          </Box>
          <Stack
            padding="16px"
            height={8 * 4}
          >
            <Heading size="md">
              <Link href={`/project/${projectName}`}>
                {projectName}
              </Link>
            </Heading>
            <Text fontSize="14px" noOfLines={3}>
              {description}
            </Text>
          </Stack>
          <Flex
            px="16px"
            pt="16px"
            pb="32px"
            direction="row"
            justify="space-evenly"
            width="100%"
          >
            <Box width="50%">
              <Flex
                direction="column"
                justify="center"
                align="center"
              >
                <Text as="b">Streaming</Text>
                <Text>
                    ~${streaming.toLocaleString()}/mo
                </Text>
              </Flex>
            </Box>
            <Spacer />
            <Box width="50%">
              <Flex
                direction="column"
                justify="center"
                align="center"
                minWidth={100}
              >
                <Text as="b">Total streamed</Text>
                <Text>
                  ~${streamed.toLocaleString()}
                </Text>
              </Flex>
            </Box>
          </Flex>
        </Stack>
      </Card>
    </Stack>
  )
}