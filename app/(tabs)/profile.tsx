import { StyleSheet, Switch, ActivityIndicator, Alert, TouchableOpacity } from 'react-native';
import { useState, useEffect } from 'react';

import { Text, View } from '@/components/Themed';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '@/components/useTheme';
import ThemeSettingsModal from '@/components/ThemeSettingsModal';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api';

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const { colors: themeColors, fontFamily, scaleFont } = useTheme();
  
  const [showThemeModal, setShowThemeModal] = useState(false);
  
  const [isAvailable, setIsAvailable] = useState(false);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [tradeType, setTradeType] = useState('plumber'); // Default/Mock

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      // Typically fetch user profile including staff details
      // Using mock endpoint or assume we get it from auth
      if (user?.id) {
        const res = await fetch(`${API_URL}/staff/${user.id}`);
        if (res.ok) {
          const data = await res.json();
          setIsAvailable(data.is_available);
          setTradeType(data.trade_type);
        } else {
          // Mock data fallback
          setIsAvailable(true);
          setTradeType('electrician');
        }
      }
    } catch (e) {
      // Mock data fallback
      setIsAvailable(true);
      setTradeType('electrician');
    } finally {
      setLoading(false);
    }
  };

  const toggleAvailability = async (value: boolean) => {
    setIsAvailable(value); // Optimistic update
    setUpdating(true);
    try {
      const res = await fetch(`${API_URL}/staff/${user?.id}/availability`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_available: value }),
      });
      if (!res.ok) {
        // Revert on failure in real app
        // setIsAvailable(!value);
        // Alert.alert('Error', 'Failed to update availability');
      }
    } catch (e) {
      // Revert on failure in real app
    } finally {
      setUpdating(false);
    }
  };

  const handleLogout = () => {
    Alert.alert(
      "Log Out",
      "Are you sure you want to log out?",
      [
        { text: "Cancel", style: "cancel" },
        { text: "Log Out", style: "destructive", onPress: () => logout() }
      ]
    );
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={themeColors.tint} />
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: themeColors.background }]}>
      <ThemeSettingsModal visible={showThemeModal} onClose={() => setShowThemeModal(false)} />
      <View style={styles.profileHeader}>
        <View style={[styles.avatar, { backgroundColor: themeColors.tint }]}>
          <Text style={[styles.avatarText, { fontFamily, fontSize: scaleFont(32) }]}>{user?.name?.charAt(0).toUpperCase() || 'S'}</Text>
        </View>
        <Text style={[styles.name, { fontFamily, fontSize: scaleFont(24), color: themeColors.text }]}>{user?.name || 'Staff User'}</Text>
        <Text style={[styles.email, { fontFamily, fontSize: scaleFont(16) }]}>{user?.email || 'staff@pgms.com'}</Text>
        <Text style={[styles.roleBadge, { fontFamily, fontSize: scaleFont(12), backgroundColor: themeColors.tint }]}>{tradeType.toUpperCase()}</Text>
      </View>

      <View style={styles.separator} lightColor="#eee" darkColor="rgba(255,255,255,0.1)" />

      <View style={styles.settingRow}>
        <View>
          <Text style={[styles.settingLabel, { fontFamily, fontSize: scaleFont(18), color: themeColors.text }]}>Available for Tickets</Text>
          <Text style={[styles.settingDescription, { fontFamily, fontSize: scaleFont(14) }]}>Toggle to receive new assignments</Text>
        </View>
        {updating ? (
          <ActivityIndicator color={themeColors.tint} />
        ) : (
          <Switch
            value={isAvailable}
            onValueChange={toggleAvailability}
            trackColor={{ false: '#767577', true: '#81b0ff' }}
            thumbColor={isAvailable ? themeColors.tint : '#f4f3f4'}
          />
        )}
      </View>

      <View style={styles.separator} lightColor="#eee" darkColor="rgba(255,255,255,0.1)" />

      <TouchableOpacity 
        style={[styles.themeBtn, { borderColor: themeColors.border || '#ccc' }]} 
        onPress={() => setShowThemeModal(true)}
      >
        <Text style={[styles.themeBtnText, { fontFamily, fontSize: scaleFont(16), color: themeColors.text }]}>Theme & Display Settings</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <Text style={[styles.logoutText, { fontFamily, fontSize: scaleFont(16) }]}>Log Out</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  profileHeader: {
    alignItems: 'center',
    paddingVertical: 30,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 15,
  },
  avatarText: {
    fontSize: 32,
    color: '#fff',
    fontWeight: 'bold',
  },
  name: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  email: {
    fontSize: 16,
    color: '#888',
    marginBottom: 10,
  },
  roleBadge: {
    backgroundColor: '#0a7ea4',
    color: '#fff',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    fontSize: 12,
    fontWeight: 'bold',
    overflow: 'hidden',
  },
  separator: {
    height: 1,
    width: '100%',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
  },
  settingLabel: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 4,
  },
  settingDescription: {
    fontSize: 14,
    color: '#888',
  },
  logoutButton: {
    marginTop: 30,
    marginHorizontal: 20,
    padding: 15,
    backgroundColor: '#ff3b30',
    borderRadius: 8,
    alignItems: 'center',
  },
  themeBtn: {
    marginTop: 30,
    marginHorizontal: 20,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
  },
  themeBtnText: {
    fontWeight: 'bold',
  },
  logoutText: {
    color: '#fff',
    fontWeight: 'bold',
  },
});
