import { useThemeContext } from '../context/ThemeContext';
import Colors from '../constants/Colors';

export function useTheme() {
  const { themeMode, primaryColor, fontFamily, uiScale, activeColorScheme } = useThemeContext();

  const baseColors = Colors[activeColorScheme === 'dark' ? 'dark' : 'light'];
  
  const colors = {
    ...baseColors,
    tint: primaryColor,
    tabIconSelected: primaryColor,
  };

  const scaleFont = (size: number) => size * uiScale;

  return {
    colors,
    fontFamily,
    uiScale,
    scaleFont,
    activeColorScheme,
  };
}
