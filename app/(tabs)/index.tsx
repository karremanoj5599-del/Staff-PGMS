import { StyleSheet, FlatList, TouchableOpacity, RefreshControl, ActivityIndicator } from 'react-native';
import { useState, useEffect } from 'react';
import { useRouter } from 'expo-router';

import { Text, View } from '@/components/Themed';
import { useAuth } from '../../context/AuthContext';
import Colors from '@/constants/Colors';
import { useColorScheme } from '@/components/useColorScheme';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api';

type Ticket = {
  id: number;
  tenant_id: number;
  issue_category: string;
  description: string;
  status: string;
  created_at: string;
};

export default function TicketsScreen() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const { user } = useAuth();
  const router = useRouter();
  const colorScheme = useColorScheme();
  const themeColors = Colors[colorScheme ?? 'light'];

  const fetchTickets = async () => {
    try {
      // In a real app, pass the token in headers
      const res = await fetch(`${API_URL}/tickets`);
      if (res.ok) {
        const data = await res.json();
        // If staff, maybe filter by assigned_staff_id, or backend does it
        setTickets(data);
      } else {
        // Load mock data if fetch fails
        loadMockData();
      }
    } catch (e) {
      loadMockData();
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const loadMockData = () => {
    setTickets([
      { id: 1, tenant_id: 101, issue_category: 'plumbing', description: 'Leaking pipe under sink', status: 'pending', created_at: '2026-07-10T10:00:00Z' },
      { id: 2, tenant_id: 102, issue_category: 'electrical', description: 'Lights not working in living room', status: 'in_progress', created_at: '2026-07-11T14:30:00Z' },
    ]);
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    fetchTickets();
  };

  const getStatusStyle = (status: string) => {
    switch (status) {
      case 'pending': return styles.status_pending;
      case 'in_progress': return styles.status_in_progress;
      case 'resolved': return styles.status_resolved;
      default: return styles.status_default;
    }
  };

  const renderItem = ({ item }: { item: Ticket }) => (
    <TouchableOpacity
      style={[styles.card, { backgroundColor: colorScheme === 'dark' ? '#333' : '#fff' }]}
      onPress={() => router.push(`/ticket/${item.id}`)}
    >
      <View style={styles.cardHeader}>
        <Text style={styles.ticketId}>#{item.id}</Text>
        <View style={[styles.statusBadge, getStatusStyle(item.status)]}>
          <Text style={styles.statusText}>{item.status.replace('_', ' ').toUpperCase()}</Text>
        </View>
      </View>
      <Text style={styles.category}>{item.issue_category.toUpperCase()}</Text>
      <Text style={styles.description} numberOfLines={2}>{item.description}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      {loading ? (
        <ActivityIndicator size="large" color={themeColors.tint} style={{ marginTop: 20 }} />
      ) : (
        <FlatList
          data={tickets}
          keyExtractor={(item) => item.id.toString()}
          renderItem={renderItem}
          contentContainerStyle={styles.listContainer}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
          }
          ListEmptyComponent={<Text style={styles.emptyText}>No tickets assigned to you.</Text>}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  listContainer: {
    padding: 16,
  },
  card: {
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
    backgroundColor: 'transparent',
  },
  ticketId: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  status_pending: { backgroundColor: '#ff9800' },
  status_in_progress: { backgroundColor: '#2196f3' },
  status_resolved: { backgroundColor: '#4caf50' },
  status_default: { backgroundColor: '#9e9e9e' },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  category: {
    fontSize: 14,
    fontWeight: '600',
    color: '#0a7ea4',
    marginBottom: 4,
  },
  description: {
    fontSize: 14,
    color: '#666',
  },
  emptyText: {
    textAlign: 'center',
    marginTop: 40,
    fontSize: 16,
    color: '#888',
  },
});
