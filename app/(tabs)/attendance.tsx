import { StyleSheet, FlatList, ActivityIndicator, TouchableOpacity } from 'react-native';
import { useState, useEffect } from 'react';

import { Text, View } from '@/components/Themed';
import { useAuth } from '../../context/AuthContext';
import Colors from '@/constants/Colors';
import { useColorScheme } from '@/components/useColorScheme';

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

type AttendanceRecord = {
  id: number;
  date: string;
  status: 'present' | 'absent' | 'leave';
  check_in_time?: string;
  check_out_time?: string;
};

export default function AttendanceScreen() {
  const [records, setRecords] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();
  const colorScheme = useColorScheme();
  const themeColors = Colors[colorScheme ?? 'light'];

  useEffect(() => {
    fetchAttendance();
  }, []);

  const fetchAttendance = async () => {
    try {
      const res = await fetch(`${API_URL}/staff/${user?.id}/attendance`);
      if (res.ok) {
        const data = await res.json();
        setRecords(data);
      } else {
        loadMockData();
      }
    } catch (e) {
      loadMockData();
    } finally {
      setLoading(false);
    }
  };

  const handleClockIn = async () => {
    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/staff/${user?.id}/attendance/clock-in`, { method: 'POST' });
      if (res.ok) {
        alert('Clocked In successfully!');
        fetchAttendance();
      } else {
        alert('Failed to clock in');
      }
    } catch (e) {
      alert('Error clocking in');
    } finally {
      setLoading(false);
    }
  };

  const handleClockOut = async () => {
    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/staff/${user?.id}/attendance/clock-out`, { method: 'POST' });
      if (res.ok) {
        alert('Clocked Out successfully!');
        fetchAttendance();
      } else {
        alert('Failed to clock out');
      }
    } catch (e) {
      alert('Error clocking out');
    } finally {
      setLoading(false);
    }
  };

  const handleRequestLeave = async () => {
    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/staff/${user?.id}/leave`, { 
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason: 'Sick Leave', dates: [new Date().toISOString()] })
      });
      if (res.ok) {
        alert('Leave request submitted!');
      } else {
        alert('Failed to submit leave request');
      }
    } catch (e) {
      alert('Error requesting leave');
    } finally {
      setLoading(false);
    }
  };

  const loadMockData = () => {
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    setRecords([
      {
        id: 1,
        date: today.toISOString().split('T')[0],
        status: 'present',
        check_in_time: '09:00 AM',
        check_out_time: '05:00 PM',
      },
      {
        id: 2,
        date: yesterday.toISOString().split('T')[0],
        status: 'present',
        check_in_time: '08:55 AM',
        check_out_time: '05:10 PM',
      },
      {
        id: 3,
        date: '2026-07-10',
        status: 'leave',
      },
    ]);
  };

  const getStatusColor = (status: string) => {
    switch(status) {
      case 'present': return '#4caf50';
      case 'absent': return '#f44336';
      case 'leave': return '#ff9800';
      default: return '#9e9e9e';
    }
  };

  const renderItem = ({ item }: { item: AttendanceRecord }) => (
    <View style={[styles.card, { backgroundColor: colorScheme === 'dark' ? '#333' : '#fff' }]}>
      <View style={styles.cardHeader}>
        <Text style={styles.dateText}>{item.date}</Text>
        <View style={[styles.statusBadge, { backgroundColor: getStatusColor(item.status) }]}>
          <Text style={styles.statusText}>{item.status.toUpperCase()}</Text>
        </View>
      </View>
      
      {item.status === 'present' && (
        <View style={styles.timesContainer}>
          <View style={styles.timeBlock}>
            <Text style={styles.timeLabel}>Check-In</Text>
            <Text style={styles.timeValue}>{item.check_in_time || '--:--'}</Text>
          </View>
          <View style={styles.timeBlock}>
            <Text style={styles.timeLabel}>Check-Out</Text>
            <Text style={styles.timeValue}>{item.check_out_time || '--:--'}</Text>
          </View>
        </View>
      )}
    </View>
  );

  return (
    <View style={styles.container}>
      {loading ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={themeColors.tint} />
        </View>
      ) : (
        <FlatList
          data={records}
          keyExtractor={(item) => item.id.toString()}
          renderItem={renderItem}
          contentContainerStyle={styles.listContainer}
          ListHeaderComponent={
            <View style={styles.headerContainer}>
              <Text style={styles.headerTitle}>Your Attendance Record</Text>
              
              <View style={styles.actionRow}>
                <TouchableOpacity style={[styles.actionButton, styles.clockInBtn]} onPress={handleClockIn}>
                  <Text style={styles.actionBtnText}>Clock In</Text>
                </TouchableOpacity>
                <TouchableOpacity style={[styles.actionButton, styles.clockOutBtn]} onPress={handleClockOut}>
                  <Text style={styles.actionBtnText}>Clock Out</Text>
                </TouchableOpacity>
              </View>
            </View>
          }
          ListEmptyComponent={
            <Text style={styles.emptyText}>No attendance records found.</Text>
          }
        />
      )}
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
  listContainer: {
    padding: 16,
  },
  headerContainer: {
    marginBottom: 20,
    backgroundColor: 'transparent',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    marginBottom: 16,
    color: '#0a7ea4',
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
    backgroundColor: 'transparent',
  },
  actionButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  clockInBtn: {
    backgroundColor: '#4caf50',
    marginRight: 8,
  },
  clockOutBtn: {
    backgroundColor: '#f44336',
    marginLeft: 8,
  },
  actionBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 16,
  },
  leaveButton: {
    backgroundColor: '#ff9800',
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  leaveBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 16,
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
    marginBottom: 12,
    backgroundColor: 'transparent',
  },
  dateText: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  statusText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  timesContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: 'transparent',
    marginTop: 8,
  },
  timeBlock: {
    alignItems: 'center',
  },
  timeLabel: {
    fontSize: 12,
    color: '#888',
    marginBottom: 4,
  },
  timeValue: {
    fontSize: 16,
    fontWeight: '600',
  },
  emptyText: {
    textAlign: 'center',
    marginTop: 40,
    fontSize: 16,
    color: '#888',
  },
});
