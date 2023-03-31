import { Box, Card, Image, Stack, Text, Heading, AspectRatio } from '@chakra-ui/react'
import Link from 'next/link'

type PoolCard = {
    poolName: string
    token: string
    streaming: number
    streamed: number
}

export const PoolCard = ({poolName, token, streaming, streamed}: PoolCard) => {
  return (
    <Stack width="352px" height="114px" maxWidth="100%">
      
      <Card direction={{ base: 'column', sm: 'row' }}
        overflow='hidden'
        variant='outline'
      >
        <Link href={`/pool/${poolName}`}>
          <Image
            src={`/img/${poolName}.png`}
            alt={poolName}
            objectFit="cover"
            width={90}
            height={"100%"}
          />
        </Link>
        <Box m={3}>
          <Heading size="md">
            <Link href={`/pool/${poolName}`}>
              {poolName} Pool
            </Link>
          </Heading>
          <Text size="xs">
            <Text as="b" size="xs">Streaming:</Text>
            {' '}{streaming.toLocaleString()} {token}/mo
          </Text>
          <Text size="xs">
            <Text as="b">Total streamed:</Text>
            {' '}
            {streamed.toLocaleString()} {token}
          </Text>
        </Box>
      </Card>
    </Stack>
  )
}