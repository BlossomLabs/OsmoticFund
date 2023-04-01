import { createContext, useState } from 'react';

const supportList: Number[] = [];
export const SupportListContext = createContext({ supportList, addItem: (i: number) => {}, removeItem: (i: number) => {}, clearList: () => {}});

export const SupportListProvider = ({ children }: any) => {
  const [supportList, setSupportList] = useState<Number[]>([]);

  const addItem = (item: number) => {
    if (supportList.includes(item)) {
      return;
    }
    setSupportList([...supportList, item])
  };

  const removeItem = (item: number) => {
    setSupportList(supportList.filter((i) => i !== item))
  };

  const clearList = () => {
    setSupportList([]);
  };

  return (
    <SupportListContext.Provider value={{ supportList, addItem, removeItem, clearList }}>
      {children}
    </SupportListContext.Provider>
  );
};
