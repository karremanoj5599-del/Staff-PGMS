import { useThemeContext } from '../context/ThemeContext';

export const useColorScheme = () => {
  const { activeColorScheme } = useThemeContext();
  return activeColorScheme;
};
