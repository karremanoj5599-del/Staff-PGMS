import React, { useState, useEffect, useRef, useCallback } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, Alert, ActivityIndicator, Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import { useAuth } from '../../context/AuthContext';

// Web QR Scanner Component
function WebQRScanner({ onScan, active }: { onScan: (data: string) => void, active: boolean }) {
  const scannerRef = useRef<any>(null);
  const containerRef = useRef<string>('qr-reader-' + Date.now());

  useEffect(() => {
    if (!active) return;

    let scanner: any = null;
    let mounted = true;

    const startScanner = async () => {
      try {
        // Dynamically import html5-qrcode (web only)
        const { Html5Qrcode } = await import('html5-qrcode');
        if (!mounted) return;

        scanner = new Html5Qrcode(containerRef.current);
        scannerRef.current = scanner;

        await scanner.start(
          { facingMode: 'environment' },
          {
            fps: 10,
            qrbox: { width: 250, height: 250 },
            aspectRatio: 1.0,
          },
          (decodedText: string) => {
            if (decodedText && mounted) {
              onScan(decodedText);
            }
          },
          () => {} // ignore scan failures (no QR found in frame)
        );
      } catch (err) {
        console.error('Scanner start error:', err);
        // Try front camera as fallback
        try {
          const { Html5Qrcode } = await import('html5-qrcode');
          if (!mounted) return;
          if (!scanner) {
            scanner = new Html5Qrcode(containerRef.current);
            scannerRef.current = scanner;
          }
          await scanner.start(
            { facingMode: 'user' },
            { fps: 10, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 },
            (decodedText: string) => {
              if (decodedText && mounted) {
                onScan(decodedText);
              }
            },
            () => {}
          );
        } catch (fallbackErr) {
          console.error('Fallback camera also failed:', fallbackErr);
        }
      }
    };

    // Small delay to ensure DOM element is mounted
    const timer = setTimeout(startScanner, 300);

    return () => {
      mounted = false;
      clearTimeout(timer);
      if (scannerRef.current) {
        scannerRef.current.stop().catch(() => {});
        scannerRef.current.clear().catch(() => {});
        scannerRef.current = null;
      }
    };
  }, [active, onScan]);

  return (
    <div
      id={containerRef.current}
      style={{
        width: '100%',
        height: '100%',
        position: 'absolute',
        top: 0,
        left: 0,
      }}
    />
  );
}

export default function ScanScreen() {
  const [scanned, setScanned] = useState(false);
  const [scannedData, setScannedData] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const { user } = useAuth();

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

  const handleScan = useCallback((data: string) => {
    if (scanned || !data) return;
    setScannedData(data);
    setScanned(true);
  }, [scanned]);

  return (
    <View style={styles.container}>
      {/* Web QR Scanner */}
      {Platform.OS === 'web' && (
        <WebQRScanner onScan={handleScan} active={!scanned} />
      )}

      {/* Overlay with scan box */}
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
  overlay: { position: 'absolute', top: 0, left: 0, right: 0, bottom: 0, justifyContent: 'center', alignItems: 'center', pointerEvents: 'none', zIndex: 2 },
  scanBox: { width: 250, height: 250, backgroundColor: 'transparent' },
  corner: { position: 'absolute', width: 40, height: 40, borderColor: '#fff' },
  topLeft: { top: 0, left: 0, borderTopWidth: 4, borderLeftWidth: 4, borderTopLeftRadius: 10 },
  topRight: { top: 0, right: 0, borderTopWidth: 4, borderRightWidth: 4, borderTopRightRadius: 10 },
  bottomLeft: { bottom: 0, left: 0, borderBottomWidth: 4, borderLeftWidth: 4, borderBottomLeftRadius: 10 },
  bottomRight: { bottom: 0, right: 0, borderBottomWidth: 4, borderRightWidth: 4, borderBottomRightRadius: 10 },
  scanText: { color: '#fff', fontSize: 18, fontWeight: 'bold', marginTop: 40 },
  loadingContainer: { position: 'absolute', bottom: 100, backgroundColor: 'rgba(255,255,255,0.9)', padding: 20, borderRadius: 12, alignItems: 'center', zIndex: 3 },
  loadingText: { marginTop: 10, fontSize: 16, fontWeight: '600', color: '#1e293b' },
  promptContainer: { position: 'absolute', bottom: 40, backgroundColor: '#fff', padding: 20, borderRadius: 16, width: '90%', alignItems: 'center', shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.25, shadowRadius: 3.84, elevation: 5, zIndex: 3 },
  promptTitle: { fontSize: 20, fontWeight: 'bold', color: '#1e293b', marginBottom: 5 },
  promptSub: { fontSize: 14, color: '#64748b', marginBottom: 20 },
  promptButtons: { flexDirection: 'row', justifyContent: 'space-between', width: '100%', gap: 10, marginBottom: 15 },
  promptBtn: { flex: 1, paddingVertical: 12, borderRadius: 8, alignItems: 'center' },
  promptBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
  cancelBtn: { paddingVertical: 10, width: '100%', alignItems: 'center' },
  cancelBtnText: { color: '#64748b', fontSize: 16, fontWeight: 'bold' }
});
