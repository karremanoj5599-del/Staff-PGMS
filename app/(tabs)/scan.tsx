import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, Alert, ActivityIndicator, Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import { Camera, CameraView } from 'expo-camera';
import { useAuth } from '../../context/AuthContext';


export default function ScanScreen() {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [facing, setFacing] = useState<'front' | 'back'>('back');
  const [scanned, setScanned] = useState(false);
  const [scannedData, setScannedData] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    (async () => {
      const { status } = await Camera.requestCameraPermissionsAsync();
      setHasPermission(status === 'granted');
    })();
  }, []);

  const processScan = async (data: string, action: 'entry' | 'exit') => {
    setLoading(true);
    try {
      const token = Platform.OS === 'web' ? localStorage.getItem('token') : await SecureStore.getItemAsync('token');
      const response = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/staff/visitors/scan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-user-id': user?.id?.toString() || '', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({ pass_code: data, action, staff_name: user?.name || '' })
      });
      const result = await response.json();
      
      if (result.success) {
        const tenantStr = result.visitor.tenant_name && result.visitor.tenant_name !== 'Unknown' 
          ? `\nRequested by: ${result.visitor.tenant_name}` 
          : '';
        Alert.alert('Success!', `Visitor ${action === 'entry' ? 'Entered' : 'Exited'}: ${result.visitor.name}${tenantStr}`);
        setScanned(false);
        setScannedData(null);
      } else {
        Alert.alert('Scan Failed', result.error || 'Invalid QR code');
        setScanned(false);
        setScannedData(null);
      }
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Failed to connect to the server');
      setScanned(false);
      setScannedData(null);
    } finally {
      setLoading(false);
    }
  };

  const handleBarCodeScanned = async ({ type, data }: { type: string, data: string }) => {
    // Prevent empty or invalid scans from triggering the prompt
    if (!data) return;
    setScannedData(data);
    setScanned(true);
  };

  if (hasPermission === null) return <View style={styles.container}><Text>Requesting camera permission...</Text></View>;
  if (hasPermission === false) return <View style={styles.container}><Text>No access to camera</Text></View>;

  return (
    <View style={styles.container}>
      <CameraView
        style={StyleSheet.absoluteFill}
        facing={facing}
        onBarcodeScanned={scanned ? undefined : handleBarCodeScanned}
        barcodeScannerSettings={{
          barcodeTypes: ["qr"],
        }}
      />
      
      {/* Camera Flip Button */}
      <TouchableOpacity 
        style={styles.flipButton} 
        onPress={() => setFacing(current => (current === 'back' ? 'front' : 'back'))}
      >
        <Text style={styles.flipText}>Flip Camera</Text>
      </TouchableOpacity>
      
      <View style={styles.overlay}>
        <View style={styles.scanBox}>
          <View style={[styles.corner, styles.topLeft]} />
          <View style={[styles.corner, styles.topRight]} />
          <View style={[styles.corner, styles.bottomLeft]} />
          <View style={[styles.corner, styles.bottomRight]} />
        </View>
        <Text style={styles.scanText}>Scan Visitor's QR Code</Text>
      </View>

      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4f46e5" />
          <Text style={styles.loadingText}>Verifying Pass...</Text>
        </View>
      )}

      {scanned && !loading && scannedData && (
        <View style={styles.promptContainer}>
          <Text style={styles.promptTitle}>Visitor Scanned</Text>
          <Text style={styles.promptSub}>Is this visitor entering or exiting?</Text>
          <View style={styles.promptButtons}>
            <TouchableOpacity style={[styles.promptBtn, { backgroundColor: '#10b981' }]} onPress={() => processScan(scannedData, 'entry')}>
              <Text style={styles.promptBtnText}>Mark Entry</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.promptBtn, { backgroundColor: '#f59e0b' }]} onPress={() => processScan(scannedData, 'exit')}>
              <Text style={styles.promptBtnText}>Mark Exit</Text>
            </TouchableOpacity>
          </View>
          <TouchableOpacity style={styles.cancelBtn} onPress={() => { setScanned(false); setScannedData(null); }}>
            <Text style={styles.cancelBtnText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000', justifyContent: 'center', alignItems: 'center' },
  flipButton: { position: 'absolute', top: 50, right: 20, backgroundColor: 'rgba(255,255,255,0.2)', padding: 10, borderRadius: 8, zIndex: 10 },
  flipText: { color: '#fff', fontWeight: 'bold' },
  overlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', pointerEvents: 'none' },
  scanBox: { width: 250, height: 250, backgroundColor: 'transparent' },
  corner: { position: 'absolute', width: 40, height: 40, borderColor: '#fff' },
  topLeft: { top: 0, left: 0, borderTopWidth: 4, borderLeftWidth: 4, borderTopLeftRadius: 10 },
  topRight: { top: 0, right: 0, borderTopWidth: 4, borderRightWidth: 4, borderTopRightRadius: 10 },
  bottomLeft: { bottom: 0, left: 0, borderBottomWidth: 4, borderLeftWidth: 4, borderBottomLeftRadius: 10 },
  bottomRight: { bottom: 0, right: 0, borderBottomWidth: 4, borderRightWidth: 4, borderBottomRightRadius: 10 },
  scanText: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginTop: 40 },
  loadingContainer: { position: 'absolute', bottom: 100, backgroundColor: 'rgba(255,255,255,0.9)', padding: 20, borderRadius: 12, alignItems: 'center' },
  loadingText: { marginTop: 10, fontSize: 16, fontWeight: '600', color: '#1e293b' },
  promptContainer: { position: 'absolute', bottom: 40, backgroundColor: '#fff', padding: 20, borderRadius: 16, width: '90%', alignItems: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 3.84, elevation: 5 },
  promptTitle: { fontSize: 20, fontWeight: 'bold', color: '#1e293b', marginBottom: 5 },
  promptSub: { fontSize: 14, color: '#64748b', marginBottom: 20 },
  promptButtons: { flexDirection: 'row', justifyContent: 'space-between', width: '100%', gap: 10, marginBottom: 15 },
  promptBtn: { flex: 1, paddingVertical: 12, borderRadius: 8, alignItems: 'center' },
  promptBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  cancelBtn: { paddingVertical: 10, width: '100%', alignItems: 'center' },
  cancelBtnText: { color: '#64748b', fontSize: 16, fontWeight: 'bold' }
});
