import 'package:flutter/material.dart';
import 'dart:async';
import 'federated_service.dart'; // This connects to the backend simulation file

void main() {
  runApp(const MyKadNexusApp());
}

class MyKadNexusApp extends StatelessWidget {
  const MyKadNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKad Nexus',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF06B6D4), // Cyan
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- SCREEN 1: LOCK SCREEN (NFC TAP) ---
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isScanning = false;

  void _simulateNFCTap() {
    setState(() => _isScanning = true);
    // Simulate processing delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "MyKad Nexus",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tap IC to Authenticate",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),
            // Ripple Animation Simulation
            if (_isScanning)
              const CircularProgressIndicator(color: Color(0xFF06B6D4))
            else
              ElevatedButton.icon(
                onPressed: _simulateNFCTap,
                icon: const Icon(Icons.nfc),
                label: const Text("Simulate NFC Tap"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 2: DASHBOARD & SCANNER ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Identity Unlocked"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {}, // Navigate to Audit Log
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("ALI BIN AHMAD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("880505-10-5555", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 5),
                      Text("● Active & Secured", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text("Quick Actions", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),

            // The Scanner Button
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConsentScreen()),
                  );
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: Border.all(color: const Color(0xFF06B6D4), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.qr_code_scanner, size: 60, color: Color(0xFF06B6D4)),
                      SizedBox(height: 15),
                      Text("Scan Clinic QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Connect to Service Provider", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            // Recovery Button
            Center(
              child: TextButton.icon(
                onPressed: (){},
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                label: const Text("I Lost My Card (Recovery)", style: TextStyle(color: Colors.redAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 3: GRANULAR CONSENT (THE HERO) ---
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isTransferring = false;
  bool _completed = false;

  void _approveAccess() async {
    setState(() => _isTransferring = true);

    // --- INTEGRATED BACKEND SIMULATION ---
    final service = FederatedNodeService();

    print("Connecting to JPN Node...");
    await service.fetchJPNData("880505-10-5555");

    print("Connecting to MoH Node...");
    await service.fetchMoHData("880505-10-5555");
    // ------------------------------------------

    setState(() {
      _isTransferring = false;
      _completed = true;
    });

    // The Security Feature: Wiping RAM
    service.wipeSessionData();

    // Auto close after success
    Future.delayed(const Duration(seconds: 2), () {
      if(mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
              SizedBox(height: 20),
              Text("Data Transferred", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Session will close automatically.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.local_hospital, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Pantai Hospital", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Requesting One-Time Access", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 30),

                  // Data Point 1
                  _buildDataRow("Identity Data", "Source: JPN Node", Icons.badge),
                  const SizedBox(height: 15),
                  // Data Point 2
                  _buildDataRow("Blood Type & Allergies", "Source: MoH Node", Icons.bloodtype),

                  const SizedBox(height: 30),
                  _isTransferring
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)))
                      : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("DENY"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approveAccess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("ALLOW"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Data is encrypted and never stored on this device.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 10)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String title, String source, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(source, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF06B6D4), size: 18),
      ],
    );
  }
}