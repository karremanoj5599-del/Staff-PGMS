import { useThemeContext } from '../context/ThemeContext';

export function useColorScheme() {
  const { activeColorScheme } = useThemeContext();
  return activeColorScheme;
}
