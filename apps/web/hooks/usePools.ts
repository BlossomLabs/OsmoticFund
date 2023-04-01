import { useContext } from 'react';
import { PoolContext } from '../providers/PoolProvider';

export const usePools = () => {
  const context = useContext(PoolContext);
  if (!context) {
    throw new Error('usePools must be used within a PoolProvider');
  }
  return context;
};
