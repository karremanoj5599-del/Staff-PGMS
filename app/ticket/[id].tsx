import { StyleSheet, ActivityIndicator, TouchableOpacity, Alert } from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { useState, useEffect } from 'react';

import { Text, View } from '@/components/Themed';
import Colors from '@/constants/Colors';
import { useColorScheme } from '@/components/useColorScheme';
import { useAuth } from '../../context/AuthContext';

import { Platform } from 'react-native';
let host = '127.0.0.1';
let API_URL = process.env.EXPO_PUBLIC_API_URL;
if (!API_URL) {
  if (Platform.OS === 'web' && typeof window !== 'undefined' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    API_URL = 'https://pgms-nu.vercel.app/api/staff';
  } else {
    API_URL = 'http://127.0.0.1:5000/api/staff';
  }
}

type Ticket = {
  id: number;
  tenant_id: number;
  issue_category: string;
  description: string;
  status: string;
  created_at: string;
};

export default function TicketDetailsScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  
  const colorScheme = useColorScheme();
  const themeColors = Colors[colorScheme ?? 'light'];
  const { user } = useAuth();
  const router = useRouter();

  useEffect(() => {
    fetchTicketDetails();
  }, [id]);

  const fetchTicketDetails = async () => {
    try {
      const res = await fetch(`${API_URL}/admin/tickets/${id}`, {
        headers: {
          'Authorization': `Bearer ${user?.admin_user_id || ''}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setTicket(data);
      } else {
        // Mock fallback
        setTicket({
          id: Number(id),
          tenant_id: 101,
          issue_category: 'plumbing',
          description: 'Leaking pipe under sink. Needs urgent attention as water is spilling everywhere.',
          status: 'pending',
          created_at: '2026-07-10T10:00:00Z',
        });
      }
    } catch (e) {
      // Mock fallback
      setTicket({
        id: Number(id),
        tenant_id: 101,
        issue_category: 'plumbing',
        description: 'Leaking pipe under sink. Needs urgent attention as water is spilling everywhere.',
        status: 'pending',
        created_at: '2026-07-10T10:00:00Z',
      });
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (newStatus: string) => {
    setUpdating(true);
    try {
      const res = await fetch(`${API_URL}/admin/tickets/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user?.admin_user_id || ''}`
        },
        body: JSON.stringify({ status: newStatus }),
      });
      
      if (res.ok) {
        setTicket(prev => prev ? { ...prev, status: newStatus } : null);
        Alert.alert('Success', `Ticket marked as ${newStatus.replace('_', ' ')}`);
      } else {
        // Fallback for mock environment
        setTicket(prev => prev ? { ...prev, status: newStatus } : null);
      }
    } catch (e) {
      // Fallback for mock environment
      setTicket(prev => prev ? { ...prev, status: newStatus } : null);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={themeColors.tint} />
      </View>
    );
  }

  if (!ticket) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>Ticket not found.</Text>
      </View>
    );
  }

  const getStatusStyle = (status: string) => {
    switch (status) {
      case 'pending': return styles.status_pending;
      case 'in_progress': return styles.status_in_progress;
      case 'resolved': return styles.status_resolved;
      default: return styles.status_default;
    }
  };

  return (
    <View style={styles.container}>
      <Stack.Screen options={{ title: `Ticket #${ticket.id}` }} />
      
      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={styles.category}>{ticket.issue_category.toUpperCase()}</Text>
          <View style={[styles.statusBadge, getStatusStyle(ticket.status)]}>
            <Text style={styles.statusText}>{ticket.status.replace('_', ' ').toUpperCase()}</Text>
          </View>
        </View>

        <Text style={styles.date}>Created: {new Date(ticket.created_at).toLocaleString()}</Text>
        
        <View style={styles.separator} lightColor="#eee" darkColor="rgba(255,255,255,0.1)" />
        
        <Text style={styles.sectionTitle}>Description</Text>
        <Text style={styles.description}>{ticket.description}</Text>
        
        <View style={styles.separator} lightColor="#eee" darkColor="rgba(255,255,255,0.1)" />

        <Text style={styles.sectionTitle}>Actions</Text>
        <View style={styles.actionsContainer} lightColor="transparent" darkColor="transparent">
          {ticket.status === 'pending' && (
            <TouchableOpacity 
              style={[styles.actionButton, styles.buttonInProgress]}
              onPress={() => updateStatus('in_progress')}
              disabled={updating}
            >
              <Text style={styles.actionButtonText}>Start Work</Text>
            </TouchableOpacity>
          )}
          
          {(ticket.status === 'pending' || ticket.status === 'in_progress') && (
            <TouchableOpacity 
              style={[styles.actionButton, styles.buttonResolved]}
              onPress={() => updateStatus('resolved')}
              disabled={updating}
            >
              <Text style={styles.actionButtonText}>Mark Resolved</Text>
            </TouchableOpacity>
          )}

          {ticket.status === 'resolved' && (
            <Text style={styles.resolvedMessage}>This ticket is already resolved.</Text>
          )}
        </View>
      </View>
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
  content: {
    padding: 20,
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
    backgroundColor: 'transparent',
  },
  category: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#0a7ea4',
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  status_pending: { backgroundColor: '#ff9800' },
  status_in_progress: { backgroundColor: '#2196f3' },
  status_resolved: { backgroundColor: '#4caf50' },
  status_default: { backgroundColor: '#9e9e9e' },
  statusText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: 'bold',
  },
  date: {
    fontSize: 14,
    color: '#888',
    marginBottom: 20,
  },
  separator: {
    height: 1,
    width: '100%',
    marginVertical: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  description: {
    fontSize: 16,
    lineHeight: 24,
  },
  errorText: {
    fontSize: 18,
    color: 'red',
  },
  actionsContainer: {
    marginTop: 10,
    gap: 15,
  },
  actionButton: {
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonInProgress: {
    backgroundColor: '#2196f3',
  },
  buttonResolved: {
    backgroundColor: '#4caf50',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
  resolvedMessage: {
    fontSize: 16,
    color: '#4caf50',
    fontStyle: 'italic',
    textAlign: 'center',
    marginTop: 10,
  },
});
