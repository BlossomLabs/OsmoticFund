import { useContext } from 'react';
import { SupportListContext } from '../providers/SupportListProvider';

export const useSupportList = () => {
  const context = useContext(SupportListContext);
  if (!context) {
    throw new Error('useSupportList must be used within a SupportListProvider');
  }
  return context;
};
  