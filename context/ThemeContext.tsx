import React, { createContext, useState, useEffect, useContext } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useColorScheme as useDeviceColorScheme } from 'react-native';

export type ThemeMode = 'light' | 'dark' | 'system';

interface ThemeContextType {
  themeMode: ThemeMode;
  setThemeMode: (mode: ThemeMode) => void;
  primaryColor: string;
  setPrimaryColor: (color: string) => void;
  fontFamily: string;
  setFontFamily: (font: string) => void;
  uiScale: number;
  setUiScale: (scale: number) => void;
  activeColorScheme: 'light' | 'dark';
}

const defaultContext: ThemeContextType = {
  themeMode: 'system',
  setThemeMode: () => {},
  primaryColor: '#3B82F6', // Default accent primary
  setPrimaryColor: () => {},
  fontFamily: 'Inter',
  setFontFamily: () => {},
  uiScale: 1.0,
  setUiScale: () => {},
  activeColorScheme: 'light',
};

export const ThemeContext = createContext<ThemeContextType>(defaultContext);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const deviceColorScheme = useDeviceColorScheme() || 'light';
  
  const [themeMode, setThemeModeState] = useState<ThemeMode>('system');
  const [primaryColor, setPrimaryColorState] = useState<string>('#3B82F6');
  const [fontFamily, setFontFamilyState] = useState<string>('Inter');
  const [uiScale, setUiScaleState] = useState<number>(1.0);

  const [isLoaded, setIsLoaded] = useState(false);

  useEffect(() => {
    const loadThemeSettings = async () => {
      try {
        const storedThemeMode = await AsyncStorage.getItem('themeMode');
        const storedPrimaryColor = await AsyncStorage.getItem('primaryColor');
        const storedFontFamily = await AsyncStorage.getItem('fontFamily');
        const storedUiScale = await AsyncStorage.getItem('uiScale');

        if (storedThemeMode) setThemeModeState(storedThemeMode as ThemeMode);
        if (storedPrimaryColor) setPrimaryColorState(storedPrimaryColor);
        if (storedFontFamily) setFontFamilyState(storedFontFamily);
        if (storedUiScale) setUiScaleState(parseFloat(storedUiScale));
      } catch (e) {
        console.error('Failed to load theme settings', e);
      } finally {
        setIsLoaded(true);
      }
    };
    loadThemeSettings();
  }, []);

  const setThemeMode = async (mode: ThemeMode) => {
    setThemeModeState(mode);
    await AsyncStorage.setItem('themeMode', mode);
  };

  const setPrimaryColor = async (color: string) => {
    setPrimaryColorState(color);
    await AsyncStorage.setItem('primaryColor', color);
  };

  const setFontFamily = async (font: string) => {
    setFontFamilyState(font);
    await AsyncStorage.setItem('fontFamily', font);
  };

  const setUiScale = async (scale: number) => {
    setUiScaleState(scale);
    await AsyncStorage.setItem('uiScale', scale.toString());
  };

  const activeColorScheme = themeMode === 'system' ? (deviceColorScheme === 'dark' ? 'dark' : 'light') : themeMode;

  if (!isLoaded) return null;

  return (
    <ThemeContext.Provider value={{
      themeMode,
      setThemeMode,
      primaryColor,
      setPrimaryColor,
      fontFamily,
      setFontFamily,
      uiScale,
      setUiScale,
      activeColorScheme,
    }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useThemeContext = () => useContext(ThemeContext);
