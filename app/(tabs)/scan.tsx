import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, Alert, ActivityIndicator, Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import { Camera, CameraView } from 'expo-camera';
import { BlurView } from 'expo-blur';
import { useAuth } from '../../context/AuthContext';


export default function ScanScreen() {
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [scanned, setScanned] = useState(false);
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
        Alert.alert('Success!', `Visitor ${action === 'entry' ? 'Entered' : 'Exited'}: ${result.visitor.name}${tenantStr}`, [
          { text: 'OK', onPress: () => setScanned(false) }
        ]);
      } else {
        Alert.alert('Scan Failed', result.error || 'Invalid QR code', [
          { text: 'Try Again', onPress: () => setScanned(false) }
        ]);
      }
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'Failed to connect to the server', [
        { text: 'OK', onPress: () => setScanned(false) }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleBarCodeScanned = async ({ type, data }: { type: string, data: string }) => {
    setScanned(true);

    Alert.alert(
      'Visitor Scanned',
      'Is this visitor entering or exiting?',
      [
        { text: 'Mark Entry', onPress: () => processScan(data, 'entry') },
        { text: 'Mark Exit', onPress: () => processScan(data, 'exit') },
        { text: 'Cancel', onPress: () => setScanned(false), style: 'cancel' }
      ]
    );
  };

  if (hasPermission === null) return <View style={styles.container}><Text>Requesting camera permission...</Text></View>;
  if (hasPermission === false) return <View style={styles.container}><Text>No access to camera</Text></View>;

  return (
    <View style={styles.container}>
      <CameraView
        style={StyleSheet.absoluteFill}
        onBarcodeScanned={scanned ? undefined : handleBarCodeScanned}
        barcodeScannerSettings={{
          barcodeTypes: ["qr"],
        }}
      />
      
      <BlurView intensity={60} tint="dark" style={styles.overlay}>
        <View style={styles.scanBox}>
          <View style={[styles.corner, styles.topLeft]} />
          <View style={[styles.corner, styles.topRight]} />
          <View style={[styles.corner, styles.bottomLeft]} />
          <View style={[styles.corner, styles.bottomRight]} />
        </View>
        <Text style={styles.scanText}>Scan Visitor's QR Code</Text>
      </BlurView>

      {loading && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#4f46e5" />
          <Text style={styles.loadingText}>Verifying Pass...</Text>
        </View>
      )}

      {scanned && !loading && (
        <TouchableOpacity style={styles.rescanButton} onPress={() => setScanned(false)}>
          <Text style={styles.rescanButtonText}>Tap to Scan Again</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000', justifyContent: 'center', alignItems: 'center' },
  overlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', backgroundColor: 'rgba(0,0,0,0.3)' },
  scanBox: { width: 250, height: 250, backgroundColor: 'transparent' },
  corner: { position: 'absolute', width: 40, height: 40, borderColor: '#fff' },
  topLeft: { top: 0, left: 0, borderTopWidth: 4, borderLeftWidth: 4, borderTopLeftRadius: 10 },
  topRight: { top: 0, right: 0, borderTopWidth: 4, borderRightWidth: 4, borderTopRightRadius: 10 },
  bottomLeft: { bottom: 0, left: 0, borderBottomWidth: 4, borderLeftWidth: 4, borderBottomLeftRadius: 10 },
  bottomRight: { bottom: 0, right: 0, borderBottomWidth: 4, borderRightWidth: 4, borderBottomRightRadius: 10 },
  scanText: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginTop: 40 },
  loadingContainer: { position: 'absolute', bottom: 100, backgroundColor: 'rgba(255,255,255,0.9)', padding: 20, borderRadius: 12, alignItems: 'center' },
  loadingText: { marginTop: 10, fontSize: 16, fontWeight: '600', color: '#1e293b' },
  rescanButton: { position: 'absolute', bottom: 50, backgroundColor: '#4f46e5', paddingHorizontal: 30, paddingVertical: 15, borderRadius: 30 },
  rescanButtonText: { color: '#fff', fontSize: 16, fontWeight: 'bold' }
});
