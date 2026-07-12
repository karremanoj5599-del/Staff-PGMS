import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Modal, ScrollView, Platform } from 'react-native';
import Slider from '@react-native-community/slider';
import { Ionicons } from '@expo/vector-icons';
import { useThemeContext, ThemeMode } from '../context/ThemeContext';
import { useTheme } from './useTheme';

interface ThemeSettingsModalProps {
  visible: boolean;
  onClose: () => void;
}

const PRIMARY_COLORS = [
  '#3B82F6', // Blue
  '#10B981', // Green
  '#F59E0B', // Yellow
  '#EC4899', // Pink
  '#8B5CF6', // Purple
];

const FONTS = [
  { name: 'Inter', value: 'Inter-Regular' },
  { name: 'Roboto', value: 'Roboto-Regular' },
  { name: 'Poppins', value: 'Poppins-Regular' },
  { name: 'Open Sans', value: 'OpenSans-Regular' },
  { name: 'Montserrat', value: 'Montserrat-Regular' },
  { name: 'Lato', value: 'Lato-Regular' },
  { name: 'Nunito', value: 'Nunito-Regular' },
  { name: 'Playfair', value: 'PlayfairDisplay-Regular' },
];

export default function ThemeSettingsModal({ visible, onClose }: ThemeSettingsModalProps) {
  const { themeMode, setThemeMode, primaryColor, setPrimaryColor, fontFamily, setFontFamily, uiScale, setUiScale } = useThemeContext();
  const { colors, scaleFont } = useTheme();

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={[styles.modalContainer, { backgroundColor: colors.background, borderColor: colors.border }]}>
          {/* Header */}
          <View style={styles.header}>
            <Text style={[styles.title, { color: colors.text, fontFamily }]}>Admin Settings</Text>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text} />
            </TouchableOpacity>
          </View>

          <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
            
            {/* Theme Mode */}
            <View style={styles.section}>
              <Text style={[styles.sectionTitle, { color: colors.text }]}>THEME MODE</Text>
              <View style={styles.row}>
                {(['dark', 'light'] as ThemeMode[]).map((mode) => (
                  <TouchableOpacity
                    key={mode}
                    style={[
                      styles.modeButton,
                      { borderColor: colors.border },
                      themeMode === mode && { borderColor: primaryColor, backgroundColor: primaryColor + '15' }
                    ]}
                    onPress={() => setThemeMode(mode)}
                  >
                    <Text style={[
                      styles.modeText,
                      { color: colors.text, fontFamily },
                      themeMode === mode && { color: primaryColor }
                    ]}>
                      {mode === 'dark' ? 'Dark Mode' : 'Light Mode'}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Primary Color */}
            <View style={styles.section}>
              <Text style={[styles.sectionTitle, { color: colors.text }]}>PRIMARY COLOR</Text>
              <View style={styles.colorRow}>
                {PRIMARY_COLORS.map((color) => (
                  <TouchableOpacity
                    key={color}
                    style={[
                      styles.colorCircle,
                      { backgroundColor: color },
                      primaryColor === color && styles.colorCircleSelected
                    ]}
                    onPress={() => setPrimaryColor(color)}
                  >
                    {primaryColor === color && <Ionicons name="checkmark" size={16} color="#FFF" />}
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Typography Font */}
            <View style={styles.section}>
              <Text style={[styles.sectionTitle, { color: colors.text }]}>TYPOGRAPHY FONT</Text>
              <View style={styles.fontGrid}>
                {FONTS.map((font) => (
                  <TouchableOpacity
                    key={font.value}
                    style={[
                      styles.fontButton,
                      { borderColor: colors.border, backgroundColor: colors.background },
                      fontFamily === font.value && { borderColor: primaryColor, backgroundColor: primaryColor + '15' }
                    ]}
                    onPress={() => setFontFamily(font.value)}
                  >
                    <Text style={[
                      styles.fontText,
                      { color: colors.text, fontFamily: font.value },
                      fontFamily === font.value && { color: primaryColor }
                    ]}>
                      {font.name}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* UI Scale */}
            <View style={styles.section}>
              <View style={styles.scaleHeader}>
                <Text style={[styles.sectionTitle, { color: colors.text }]}>UI SCALE (BASE FONT SIZE)</Text>
                <Text style={[styles.scaleValue, { color: primaryColor, fontFamily }]}>{Math.round(16 * uiScale)}PX</Text>
              </View>
              <Slider
                style={styles.slider}
                minimumValue={0.75}
                maximumValue={1.25}
                step={0.05}
                value={uiScale}
                onValueChange={setUiScale}
                minimumTrackTintColor={primaryColor}
                maximumTrackTintColor={colors.border}
                thumbTintColor={primaryColor}
              />
              <View style={styles.scaleLabels}>
                <Text style={[styles.scaleLabel, { color: colors.text }]}>Small (12px)</Text>
                <Text style={[styles.scaleLabel, { color: colors.text }]}>Default (16px)</Text>
                <Text style={[styles.scaleLabel, { color: colors.text }]}>Large (20px)</Text>
              </View>
            </View>

          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContainer: {
    width: '90%',
    maxWidth: 400,
    maxHeight: '85%',
    borderRadius: 16,
    borderWidth: 1,
    padding: 20,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  closeButton: {
    padding: 4,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: '600',
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  modeButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
  },
  modeText: {
    fontSize: 14,
    fontWeight: '500',
  },
  colorRow: {
    flexDirection: 'row',
    gap: 12,
  },
  colorCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  colorCircleSelected: {
    borderWidth: 2,
    borderColor: '#FFF',
  },
  fontGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  fontButton: {
    width: '48%',
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    alignItems: 'center',
  },
  fontText: {
    fontSize: 14,
  },
  scaleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  scaleValue: {
    fontSize: 12,
    fontWeight: '600',
  },
  slider: {
    width: '100%',
    height: 40,
  },
  scaleLabels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 4,
  },
  scaleLabel: {
    fontSize: 11,
  },
});
