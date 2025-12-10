import 'package:flutter/material.dart';
import 'dart:async';

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

// ==========================================
// SCREEN 1: LOCK SCREEN
// ==========================================
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isScanning = false;

  void _simulateNFCTap() {
    setState(() => _isScanning = true);
    // Simulate processing delay (1.5 seconds)
    Future.delayed(const Duration(milliseconds: 1500), () {
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

// ==========================================
// SCREEN 2: DASHBOARD
// ==========================================
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuditLogScreen()),
              );
            },
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

            // SCANNER BUTTON
            Center(
              child: GestureDetector(
                onTap: () {
                  // Go to Fake Scanner -> Then Consent Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScannerSimulationScreen()),
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

            // RECOVERY BUTTON
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecoveryScreen()),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                label: const Text("I Lost My Card (Recovery)", style: TextStyle(color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// NEW SCREEN: FAKE SCANNER ANIMATION
// ==========================================
class ScannerSimulationScreen extends StatefulWidget {
  const ScannerSimulationScreen({super.key});

  @override
  State<ScannerSimulationScreen> createState() => _ScannerSimulationScreenState();
}

class _ScannerSimulationScreenState extends State<ScannerSimulationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1. Setup Scanning Animation Loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Auto-Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConsentScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Camera Placeholder
          Container(
            color: Colors.black54,
            child: const Center(
              child: Icon(Icons.qr_code, size: 200, color: Colors.white10),
            ),
          ),

          // Viewfinder Box
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Animated Scanning Line (The Laser)
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, _controller.value * 2 - 1),
                    child: Container(
                      height: 2,
                      width: 240,
                      decoration: const BoxDecoration(
                        color: Color(0xFF06B6D4), // Cyan Laser
                        boxShadow: [
                          BoxShadow(color: Color(0xFF06B6D4), blurRadius: 10, spreadRadius: 1)
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Instruction Text
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              "Align QR Code within frame",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Close Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 3: CONSENT POPUP
// ==========================================
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isTransferring = false;
  bool _completed = false;

  void _approveAccess() {
    setState(() => _isTransferring = true);
    // Simulate API Call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTransferring = false;
        _completed = true;
      });
      // Auto close popup
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
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

                  _buildDataRow("Identity Data", "Source: JPN Node", Icons.badge),
                  const SizedBox(height: 15),
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

// ==========================================
// SCREEN 4: AUDIT LOG (History)
// ==========================================
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Access History"),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLogItem("Pantai Hospital", "Name, Blood Type", "Just Now", Colors.green),
          _buildLogItem("Maybank", "Identity Verification", "Yesterday", Colors.amber),
          _buildLogItem("JPJ Roadblock", "License Check", "12 Dec 2024", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLogItem(String title, String details, String time, Color color) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(Icons.security, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(details, style: const TextStyle(color: Colors.grey)),
        trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

// ==========================================
// SCREEN 5: RECOVERY (Shard Animation)
// ==========================================
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _startRecovery();
  }

  void _startRecovery() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _step = 1); // Bank Verified
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _step = 2); // Family Verified
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _step = 3); // Gov Verified
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Social Recovery"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Restoring Identity...", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Contacting trusted guardians to rebuild private key.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            _buildShardStep("Bank Guardian (Maybank)", _step >= 1),
            _buildShardStep("Family Guardian (Wife)", _step >= 2),
            _buildShardStep("Government Node (JPN)", _step >= 3),

            const Spacer(),
            if (_step == 3)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  "SUCCESS: Identity Restored on new device.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShardStep(String title, bool isDone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withOpacity(0.1) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDone ? Colors.green : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.hourglass_empty,
            color: isDone ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 15),
          Text(title, style: TextStyle(
              color: isDone ? Colors.white : Colors.grey,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );

  }
}