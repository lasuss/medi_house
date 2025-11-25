//show QR code to scan by Doctor
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Make sure to add qr_flutter to your pubspec.yaml

class PatientShowQR extends StatefulWidget {
  const PatientShowQR({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  State<PatientShowQR> createState() => _PatientShowQRState();
}

class _PatientShowQRState extends State<PatientShowQR> {
  // --- Placeholder Data ---
  // In a real app, this data should come from your state management (e.g., a Provider or Bloc)
  // which holds the logged-in user's information.
  String _qrData = 'MH123456789'; // The initial data for the QR code (e.g., user ID)
  final String _patientName = 'John Appleseed';
  final String _recordId = 'MH123456789';

  /// This function simulates refreshing the QR code.
  /// In a real app, this would generate a new secure, temporary token.
  void _refreshCode() {
    setState(() {
      _qrData = 'MH123456789-${DateTime.now().millisecondsSinceEpoch}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code has been refreshed.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: const Text(
          'Your Medical ID',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF172A46),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _patientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Record ID: $_recordId',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.2), // Light teal accent
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: QrImageView(
                    padding: const EdgeInsets.all(20),
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Present this code to your doctor or pharmacist to access your records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This code contains a secure, temporary link to your record.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _refreshCode,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Refresh Code',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
