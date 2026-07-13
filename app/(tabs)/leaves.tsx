import { StyleSheet, FlatList, ActivityIndicator, TouchableOpacity, TextInput, Modal, Alert } from 'react-native';
import { useState, useEffect, useCallback } from 'react';
import { useFocusEffect } from 'expo-router';

import { Text, View } from '@/components/Themed';
import { useAuth } from '../../context/AuthContext';
import Colors from '@/constants/Colors';
import { useColorScheme } from '@/components/useColorScheme';

import { Platform } from 'react-native';
let host = '127.0.0.1';
let API_URL = process.env.EXPO_PUBLIC_API_URL;
if (!API_URL || API_URL.includes('localhost') || API_URL.includes('127.0.0.1')) {
  if (Platform.OS === 'web' && typeof window !== 'undefined' && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    API_URL = 'https://pgms-nu.vercel.app/api';
  } else {
    API_URL = 'http://127.0.0.1:5000/api';
  }
}

type LeaveRecord = {
  id: number;
  start_date: string;
  end_date: string;
  reason: string;
  status: 'Pending' | 'Approved' | 'Rejected';
};

export default function LeavesScreen() {
  const [leaves, setLeaves] = useState<LeaveRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalVisible, setModalVisible] = useState(false);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [reason, setReason] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const { user } = useAuth();
  const colorScheme = useColorScheme();
  const themeColors = Colors[colorScheme ?? 'light'];

  useFocusEffect(
    useCallback(() => {
      fetchLeaves();
    }, [user])
  );

  const fetchLeaves = async () => {
    if (!user || !user.id) return;
    try {
      const res = await fetch(`${API_URL}/admin/staff/${user.id}/leaves`, {
        headers: { 'Authorization': `Bearer ${user.admin_user_id || ''}` }
      });
      if (res.ok) {
        const data = await res.json();
        setLeaves(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleRequestLeave = async () => {
    if (!startDate || !endDate || !reason) {
      alert('Please fill all fields');
      return;
    }
    setSubmitting(true);
    try {
      const res = await fetch(`${API_URL}/admin/staff/${user?.id}/leave`, { 
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${user?.admin_user_id || ''}`
        },
        body: JSON.stringify({ start_date: startDate, end_date: endDate, reason })
      });
      if (res.ok) {
        alert('Leave request submitted!');
        setModalVisible(false);
        setStartDate('');
        setEndDate('');
        setReason('');
        fetchLeaves();
      } else {
        alert('Failed to submit leave request');
      }
    } catch (e) {
      alert('Error requesting leave');
    } finally {
      setSubmitting(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch(status) {
      case 'Approved': return '#4caf50';
      case 'Rejected': return '#f44336';
      case 'Pending': return '#ff9800';
      default: return '#9e9e9e';
    }
  };

  const renderItem = ({ item }: { item: LeaveRecord }) => (
    <View style={[styles.card, { backgroundColor: colorScheme === 'dark' ? '#333' : '#fff' }]}>
      <View style={styles.cardHeader}>
        <Text style={styles.dateText}>{new Date(item.start_date).toLocaleDateString()} - {new Date(item.end_date).toLocaleDateString()}</Text>
        <View style={[styles.statusBadge, { backgroundColor: getStatusColor(item.status) }]}>
          <Text style={styles.statusText}>{item.status.toUpperCase()}</Text>
        </View>
      </View>
      <Text style={styles.reasonLabel}>Reason:</Text>
      <Text style={styles.reasonText}>{item.reason}</Text>
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
          data={leaves}
          keyExtractor={(item) => item.id.toString()}
          renderItem={renderItem}
          contentContainerStyle={styles.listContainer}
          ListHeaderComponent={
            <View style={styles.headerContainer}>
              <Text style={styles.headerTitle}>Leave Requests</Text>
              <TouchableOpacity style={styles.leaveButton} onPress={() => setModalVisible(true)}>
                <Text style={styles.leaveBtnText}>+ New Request</Text>
              </TouchableOpacity>
            </View>
          }
          ListEmptyComponent={
            <Text style={styles.emptyText}>No leave requests found.</Text>
          }
        />
      )}

      <Modal
        animationType="slide"
        transparent={true}
        visible={modalVisible}
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalView, { backgroundColor: colorScheme === 'dark' ? '#1e1e1e' : '#fff' }]}>
            <Text style={styles.modalTitle}>Request Leave</Text>
            
            <Text style={styles.label}>Start Date (YYYY-MM-DD)</Text>
            <TextInput
              style={[styles.input, { color: themeColors.text, borderColor: '#ccc' }]}
              placeholder="e.g. 2026-08-01"
              placeholderTextColor="#888"
              value={startDate}
              onChangeText={setStartDate}
            />

            <Text style={styles.label}>End Date (YYYY-MM-DD)</Text>
            <TextInput
              style={[styles.input, { color: themeColors.text, borderColor: '#ccc' }]}
              placeholder="e.g. 2026-08-03"
              placeholderTextColor="#888"
              value={endDate}
              onChangeText={setEndDate}
            />

            <Text style={styles.label}>Reason</Text>
            <TextInput
              style={[styles.textArea, { color: themeColors.text, borderColor: '#ccc' }]}
              placeholder="Explain why you are requesting leave"
              placeholderTextColor="#888"
              multiline
              numberOfLines={4}
              value={reason}
              onChangeText={setReason}
            />

            <View style={styles.modalButtons}>
              <TouchableOpacity 
                style={[styles.button, styles.cancelBtn]} 
                onPress={() => setModalVisible(false)}
              >
                <Text style={styles.buttonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.button, styles.submitBtn]} 
                onPress={handleRequestLeave}
                disabled={submitting}
              >
                {submitting ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Submit</Text>}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  listContainer: { padding: 16 },
  headerContainer: { marginBottom: 20, backgroundColor: 'transparent' },
  headerTitle: { fontSize: 22, fontWeight: 'bold', marginBottom: 16, color: '#0a7ea4' },
  leaveButton: { backgroundColor: '#0a7ea4', paddingVertical: 12, borderRadius: 8, alignItems: 'center' },
  leaveBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
  card: { borderRadius: 8, padding: 16, marginBottom: 16, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 4, elevation: 3 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, backgroundColor: 'transparent' },
  dateText: { fontSize: 16, fontWeight: 'bold' },
  statusBadge: { paddingHorizontal: 10, paddingVertical: 5, borderRadius: 6 },
  statusText: { color: '#fff', fontSize: 12, fontWeight: 'bold' },
  reasonLabel: { fontSize: 12, color: '#888', marginBottom: 4 },
  reasonText: { fontSize: 14 },
  emptyText: { textAlign: 'center', marginTop: 40, fontSize: 16, color: '#888' },
  
  modalOverlay: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.5)' },
  modalView: { width: '90%', borderRadius: 12, padding: 20, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 4, elevation: 5 },
  modalTitle: { fontSize: 20, fontWeight: 'bold', marginBottom: 20, textAlign: 'center' },
  label: { fontSize: 14, marginBottom: 8, fontWeight: '500' },
  input: { borderWidth: 1, borderRadius: 8, padding: 12, marginBottom: 16, fontSize: 16 },
  textArea: { borderWidth: 1, borderRadius: 8, padding: 12, marginBottom: 20, fontSize: 16, textAlignVertical: 'top' },
  modalButtons: { flexDirection: 'row', justifyContent: 'space-between', backgroundColor: 'transparent' },
  button: { flex: 1, padding: 14, borderRadius: 8, alignItems: 'center' },
  cancelBtn: { backgroundColor: '#f44336', marginRight: 8 },
  submitBtn: { backgroundColor: '#4caf50', marginLeft: 8 },
  buttonText: { color: '#fff', fontWeight: 'bold', fontSize: 16 }
});
