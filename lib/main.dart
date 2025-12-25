import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';

// =========================================================
// ⚡ CONTROL CENTER (CHANGE THIS FOR PRODUCTION)
// =========================================================
const bool isProduction = false; // Set to TRUE to hide Dev buttons
// =========================================================

// GLOBAL CONTROLLERS (For Instant UI Updates)
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
ValueNotifier<String> pewarisStatusNotifier = ValueNotifier("Loading...");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyKadNexusApp());
}

class MyKadNexusApp extends StatelessWidget {
  const MyKadNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'MyKad Nexus',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF06B6D4),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF06B6D4),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0),
          ),
          themeMode: mode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// ==========================================
// 0. ANIMATED SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StartupCheck()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) {
              try {
                return Image.asset('assets/app_icon.png', width: 120, errorBuilder: (c, o, s) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.shield, size: 80, color: Color(0xFF06B6D4)),
                  );
                });
              } catch (e) {
                return const Icon(Icons.shield, size: 80, color: Color(0xFF06B6D4));
              }
            }),
            const SizedBox(height: 20),
            const Text(
                "MyKad Nexus",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)
            ),
            const SizedBox(height: 10),
            const Text("Sovereign Identity Wallet", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Color(0xFF06B6D4)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 0.1 STARTUP CONTROLLER
// ==========================================
class StartupCheck extends StatefulWidget {
  const StartupCheck({super.key});
  @override
  State<StartupCheck> createState() => _StartupCheckState();
}

class _StartupCheckState extends State<StartupCheck> {
  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }
  void _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    bool isRegistered = prefs.getBool('isRegistered') ?? false;
    if (mounted) {
      if (isRegistered) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
      }
    }
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ==========================================
// 1. REGISTRATION SCREEN (Updated Flow: eKYC -> NFC -> Face -> Bio)
// ==========================================
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  final TextEditingController _icController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  // Binding State Variables
  bool _nfcBound = false;
  String _boundID = "";

  // --- PLAN B: YOUR RHB SERIAL NUMBER ---
  final String _targetSerial = "99:FE:E6:50";

  void _devForceRegister() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRegistered', true);
    await prefs.setString('userIC', "880505-10-5555");
    await prefs.setString('userName', "Ali Bin Ahmad (Dev)");
    await prefs.setString('userPewaris', "Not Set");
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration"),
        actions: !isProduction ? [
          TextButton(onPressed: _devForceRegister, child: const Text("DEV: SKIP", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
        ] : [],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _currentStep == 0 ? _buildInputStep() :
          _currentStep == 1 ? _buildeKYCStep() :
          _currentStep == 2 ? _buildNFCStep() :
          _currentStep == 3 ? _buildFaceScanStep() : // NEW MANDATORY STEP
          _buildBioStep(),
        ),
      ),
    );
  }

  // Step 0: Input
  Widget _buildInputStep() {
    return Column(
      children: [
        const Icon(Icons.app_registration, size: 80, color: Color(0xFF06B6D4)),
        const SizedBox(height: 20),
        const Text("Welcome to MyKad Nexus", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Enter your IC Number to begin.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        TextField(
          controller: _icController,
          decoration: InputDecoration(filled: true, hintText: "Example: 990101-10-5555", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.badge)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () { if (_icController.text.length > 5) setState(() => _currentStep = 1); },
          child: const Text("Register Identity"),
        )
      ],
    );
  }

  // Step 1: eKYC
  Widget _buildeKYCStep() {
    return Column(
      children: [
        const Text("eKYC Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        _buildFakeScanButton("Scan IC Front"),
        const SizedBox(height: 15),
        _buildFakeScanButton("Scan IC Back"),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: () => setState(() => _currentStep = 2), child: const Text("Proceed to Device Binding"))
      ],
    );
  }

  Widget _buildFakeScanButton(String label) {
    return Container(
      width: double.infinity, height: 100,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.camera_alt, color: Colors.grey), Text(label)])),
    );
  }

  // Step 2: NFC Binding
  Widget _buildNFCStep() {
    if (!_nfcBound) _startBindingNFC();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.nfc, size: 16, color: Colors.blue), SizedBox(width: 8), Text("MODE: MyKad NFC Binding", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))]),
        ),
        const SizedBox(height: 30),

        Icon(_nfcBound ? Icons.check_circle : Icons.nfc, size: 80, color: _nfcBound ? Colors.green : Colors.amber),
        const SizedBox(height: 20),
        Text(_nfcBound ? "Binding Successful!" : "Device Binding", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

        // --- CHANGED: HIDE ID AFTER BINDING ---
        if (!_nfcBound)
          const Text("Tap your MyKad to bind.", style: TextStyle(color: Colors.grey)),

        const SizedBox(height: 30),

        if (_nfcBound)
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => setState(() => _currentStep = 3), // GO TO FACE SCAN
              child: const Text("Continue to Face Scan")
          )
        else ...[
          const CircularProgressIndicator(color: Colors.amber),
          const SizedBox(height: 20),

          if (!isProduction)
            OutlinedButton.icon(
              onPressed: () {
                if (Vibration.hasVibrator() != null) Vibration.vibrate();
                setState(() {
                  _nfcBound = true;
                  _boundID = "$_targetSerial (Simulated)";
                });
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('bound_card_id', _targetSerial);
                });
              },
              icon: const Icon(Icons.touch_app),
              label: const Text("DEV: SIMULATE CARD TAP"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
            ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              NfcManager.instance.stopSession();
              // Skip NFC, go straight to Face
              setState(() => _currentStep = 3);
            },
            child: const Text("Phone doesn't have NFC? Skip", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
          ),
        ]
      ],
    );
  }

  // Step 3: Face Scanning (Mandatory)
  Widget _buildFaceScanStep() {
    return Column(
      children: [
        const Icon(Icons.face_retouching_natural, size: 80, color: Color(0xFF06B6D4)),
        const SizedBox(height: 20),
        const Text("Facial Liveness Check", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("Verify it's really you", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            try { await picker.pickImage(source: ImageSource.camera); } catch(e) {/*ignore*/}
            showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
            await Future.delayed(const Duration(seconds: 2));
            if(mounted) {
              Navigator.pop(context);
              setState(() => _currentStep = 4); // GO TO BIOMETRICS
            }
          },
          icon: const Icon(Icons.camera_front), label: const Text("Start Face Scan"),
        ),
      ],
    );
  }

  void _startBindingNFC() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      String scannedID = "Unknown";

      try {
        List<int>? idBytes;
        if (tag.data['nfca'] != null) idBytes = List<int>.from(tag.data['nfca']['identifier']);
        else if (tag.data['isodep'] != null) idBytes = List<int>.from(tag.data['isodep']['identifier']);
        else if (tag.data['mifare'] != null) idBytes = List<int>.from(tag.data['mifare']['identifier']);

        if (idBytes != null) {
          scannedID = idBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
        }
      } catch (e) { /* ignore */ }

      if (scannedID != "Unknown") {
        if (Vibration.hasVibrator() != null) Vibration.vibrate();

        setState(() {
          _nfcBound = true;
          _boundID = scannedID;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bound_card_id', scannedID);

        NfcManager.instance.stopSession();
      } else {
        var ndef = Ndef.from(tag);
        if (ndef != null) {
          if (Vibration.hasVibrator() != null) Vibration.vibrate();
          setState(() { _nfcBound = true; _boundID = "NDEF Tag (Bound)"; });
          NfcManager.instance.stopSession();
        }
      }
    });
  }

  // Step 4: Biometrics Setup (Last Step)
  Widget _buildBioStep() {
    return Column(
      children: [
        const Icon(Icons.fingerprint, size: 80, color: Color(0xFF06B6D4)),
        const SizedBox(height: 20),
        const Text("Secure Your App", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("Enable Fingerprint / System Lock", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: _finishRegistration, child: const Text("Enable & Finish Setup"))
      ],
    );
  }

  void _finishRegistration() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(localizedReason: 'Scan to enable biometric login', options: const AuthenticationOptions(stickyAuth: true));
    } catch (e) { authenticated = true; }
    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true);
      await prefs.setString('userIC', _icController.text);
      await prefs.setString('userName', "Ali Bin Ahmad");
      await prefs.setString('userPewaris', "Not Set");
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    }
  }
}

// ==========================================
// 2. LOGIN SCREEN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final String _targetSerial = "99:FE:E6:50"; // RHB Master Key

  @override
  void initState() {
    super.initState();
    _startNFCLogin();
  }

  void _startNFCLogin() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      String scannedID = "";

      try {
        List<int>? idBytes;
        if (tag.data['nfca'] != null) idBytes = List<int>.from(tag.data['nfca']['identifier']);
        else if (tag.data['isodep'] != null) idBytes = List<int>.from(tag.data['isodep']['identifier']);

        if (idBytes != null) {
          scannedID = idBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
        }
      } catch (e) { /* ignore */ }

      final prefs = await SharedPreferences.getInstance();
      String? registeredID = prefs.getString('bound_card_id');

      bool isMatch = (scannedID == registeredID) || (scannedID == _targetSerial);
      if (registeredID == null && scannedID == _targetSerial) isMatch = true;

      if (isMatch && scannedID.isNotEmpty) {
        if (Vibration.hasVibrator() != null) Vibration.vibrate();
        if (mounted) _goToDashboard(isMigration: true);
        NfcManager.instance.stopSession();
      } else {
        NfcManager.instance.stopSession(errorMessage: "Wrong Card! Please tap the bound MyKad.");
      }
    });
  }

  void _startBioLogin() async {
    try {
      bool authenticated = await auth.authenticate(localizedReason: 'Authenticate to access identity', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true));
      if (authenticated) _goToDashboard(isMigration: false);
    } catch (e) { /* error */ }
  }

  void _goToDashboard({required bool isMigration}) {
    if (isMigration) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device Bound. Previous sessions revoked."), backgroundColor: Colors.blue));
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        actions: !isProduction ? [
          TextButton(onPressed: () => _goToDashboard(isMigration: false), child: const Text("DEV: LOGIN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
        ] : [],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Color(0xFF06B6D4)),
            const SizedBox(height: 20),
            const Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            const Text("Tap MyKad to Login", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text("- OR -"),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: _startBioLogin, icon: const Icon(Icons.fingerprint), label: const Text("Use Fingerprint / FaceID")),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. DASHBOARD LISTENER
// ==========================================
class DashboardListenerWrapper extends StatefulWidget {
  final Widget child;
  const DashboardListenerWrapper({super.key, required this.child});
  @override
  State<DashboardListenerWrapper> createState() => _DashboardListenerWrapperState();
}

class _DashboardListenerWrapperState extends State<DashboardListenerWrapper> {
  StreamSubscription? _recoveryListener;
  StreamSubscription? _pewarisIncomingListener;
  StreamSubscription? _mySentRequestListener;
  String? _myIC;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final prefs = await SharedPreferences.getInstance();
    _myIC = prefs.getString('userIC');
    if (_myIC == null) return;
    String safeIC = _myIC!.replaceAll('-', '');

    _recoveryListener = FirebaseDatabase.instance.ref("recovery_mailbox/$safeIC").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['status'] == 'pending') {
        _showRecoveryDialog(data['code'].toString(), data['requester'].toString());
      }
    });

    _pewarisIncomingListener = FirebaseDatabase.instance.ref("pewaris_requests/$safeIC").onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['status'] == 'pending') {
        _showPewarisInviteDialog(data['requesterName'].toString(), data['relation'].toString(), data['requesterIC'].toString());
      }
    });

    String? pendingTarget = prefs.getString('pending_pewaris_ic');
    if (pendingTarget != null) {
      _mySentRequestListener = FirebaseDatabase.instance.ref("pewaris_requests/$pendingTarget").onValue.listen((event) {
        final data = event.snapshot.value as Map?;
        if (data != null && data['status'] == 'accepted') {
          String savedRelation = prefs.getString('pending_pewaris_relation') ?? "Guardian";
          String newStatus = "Active ($savedRelation)";

          prefs.setString('userPewaris', newStatus);
          prefs.remove('pending_pewaris_ic');
          prefs.remove('pending_pewaris_relation');

          pewarisStatusNotifier.value = newStatus;

          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pewaris Accepted Your Request!"), backgroundColor: Colors.green));
          }
        }
      });
    }
  }

  void _showRecoveryDialog(String correctCode, String requesterName) {
    TextEditingController codeController = TextEditingController();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("$requesterName needs help!"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Enter code displayed on their screen:"), TextField(controller: codeController, keyboardType: TextInputType.number, textAlign: TextAlign.center)]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ignore")),
          ElevatedButton(onPressed: () async {
            if (codeController.text == correctCode) {
              String safeIC = _myIC!.replaceAll('-', '');
              await FirebaseDatabase.instance.ref("recovery_mailbox/$safeIC").update({'status': 'approved'});
              Navigator.pop(ctx);
            }
          }, child: const Text("APPROVE"))
        ],
      ),
    );
  }

  void _showPewarisInviteDialog(String name, String relation, String requesterIC) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Legacy Request"),
        content: Text("$name wants to add you as their Pewaris ($relation)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Decline")),
          ElevatedButton(onPressed: () async {
            String mySafeIC = _myIC!.replaceAll('-', '');
            await FirebaseDatabase.instance.ref("pewaris_requests/$mySafeIC").update({'status': 'accepted'});
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accepted Pewaris Request")));
          }, child: const Text("ACCEPT"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recoveryListener?.cancel();
    _pewarisIncomingListener?.cancel();
    _mySentRequestListener?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.child;
}

// ==========================================
// 4. DASHBOARD SCREEN
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = "Loading...", ic = "...", pewaris = "Loading...";

  @override
  void initState() { super.initState(); _loadUserData(); }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? "Ali Bin Ahmad";
      ic = prefs.getString('userIC') ?? "880505-10-5555";
      pewarisStatusNotifier.value = prefs.getString('userPewaris') ?? "Not Set";
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardListenerWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("MyKad Nexus", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => _loadUserData())),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]), borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(ic, style: const TextStyle(color: Color(0xFF06B6D4)))])]),
                      const Divider(color: Colors.white24, height: 30),
                      ValueListenableBuilder<String>(
                          valueListenable: pewarisStatusNotifier,
                          builder: (context, status, _) {
                            return Row(children: [const Icon(Icons.family_restroom, color: Colors.grey, size: 18), const SizedBox(width: 10), Text("Pewaris: $status", style: const TextStyle(color: Colors.white70))]);
                          }
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen())),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey[200], borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF06B6D4), width: 2)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner, size: 60, color: Color(0xFF06B6D4)), SizedBox(height: 10), Text("Scan Service QR", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildBtn(Icons.history, "History", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuditLogScreen())))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildBtn(Icons.shield, "Recovery", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecoveryScreen())))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
        child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.bold))]),
      ),
    );
  }
}

// ==========================================
// 5. SCANNER & CONSENT
// ==========================================
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ConsentScreen(sessionId: barcodes.first.rawValue!)));
          }
        },
      ),
    );
  }
}

class ConsentScreen extends StatefulWidget {
  final String sessionId;
  const ConsentScreen({super.key, required this.sessionId});
  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final Map<String, bool> _permissions = {'Full Name': true, 'IC Number': true, 'Blood Type': true, 'Allergy Info': true};

  void _triggerApproval() async {
    bool authenticated = false;
    try { authenticated = await auth.authenticate(localizedReason: 'Biometric Approval Required', options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true)); } catch (e) { authenticated = true; }
    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        "name": _permissions['Full Name']! ? (prefs.getString('userName') ?? "Ali") : "ACCESS DENIED",
        "ic": _permissions['IC Number']! ? (prefs.getString('userIC') ?? "88") : "ACCESS DENIED",
        "blood": _permissions['Blood Type']! ? "O+" : "ACCESS DENIED",
        "allergies": _permissions['Allergy Info']! ? "Penicillin" : "ACCESS DENIED",
        "status": "completed",
      };
      await FirebaseDatabase.instance.ref("requests/${widget.sessionId}").set(data);
      List<String> history = prefs.getStringList('audit_history') ?? [];
      history.insert(0, "Pantai Hospital|Shared Data|${DateTime.now().toString()}");
      await prefs.setStringList('audit_history', history);
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data Sent!"), backgroundColor: Colors.green)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permission Request")),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text("Uncheck items to deny access.")),
          Expanded(child: ListView(children: _permissions.keys.map((key) => SwitchListTile(title: Text(key), subtitle: Text(_permissions[key]! ? "Granted" : "Denied", style: TextStyle(color: _permissions[key]! ? Colors.green : Colors.red)), value: _permissions[key]!, onChanged: (val) => setState(() => _permissions[key] = val))).toList())),
          Padding(padding: const EdgeInsets.all(20), child: ElevatedButton.icon(onPressed: _triggerApproval, icon: const Icon(Icons.fingerprint), label: const Text("APPROVE WITH BIOMETRICS"), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white)))
        ],
      ),
    );
  }
}

// ==========================================
// 6. HISTORY SCREEN
// ==========================================
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<String> logs = [];
  @override
  void initState() { super.initState(); SharedPreferences.getInstance().then((prefs) => setState(() => logs = prefs.getStringList('audit_history') ?? [])); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Access History")),
      body: ListView.builder(itemCount: logs.length, itemBuilder: (ctx, i) { final parts = logs[i].split('|'); return ListTile(leading: const Icon(Icons.history, color: Colors.blue), title: Text(parts.length > 0 ? parts[0] : "?"), subtitle: Text(parts.length > 2 ? parts[2].substring(0, 16) : "-")); }),
    );
  }
}

// ==========================================
// 7. RECOVERY SCREEN (Total Loss Option Hidden)
// ==========================================
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  int _state = 0;
  String _code = "00";
  bool _pewarisApproved = false;

  // NEW LOGIC VARS
  bool _hasPewaris = false;
  String _pewarisIC = "";

  @override
  void initState() {
    super.initState();
    _checkPewarisStatus();
  }

  void _checkPewarisStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String p = prefs.getString('userPewaris') ?? "Not Set";

    if (p.startsWith("Active")) {
      setState(() {
        _hasPewaris = true;
        _pewarisIC = "990101-10-1111";
      });
    }
  }

  void _startRecovery() async {
    setState(() { _state = 1; _code = (Random().nextInt(90) + 10).toString(); });

    await Future.delayed(const Duration(seconds: 1));
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("JPN Notified of Lost Card")));

    if (_hasPewaris) {
      // PATH A: HAS PEWARIS
      String safeTarget = _pewarisIC.replaceAll('-', '');
      final ref = FirebaseDatabase.instance.ref("recovery_mailbox/$safeTarget");
      await ref.set({ "code": _code, "requester": "Ali Bin Ahmad", "status": "pending" });

      ref.child("status").onValue.listen((event) {
        if (event.snapshot.value == "approved" && mounted) {
          setState(() => _pewarisApproved = true);
          if (Vibration.hasVibrator() != null) Vibration.vibrate();
        }
      });
    } else {
      // PATH B: NO PEWARIS
      await Future.delayed(const Duration(seconds: 3));
      if(mounted) {
        setState(() => _pewarisApproved = true);
        if (Vibration.hasVibrator() != null) Vibration.vibrate();
      }
    }
  }

  void _showTotalLossHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("Total Loss Detected")]),
        content: const Text("You have lost both your ID Token (IC) and Trusted Device.\n\nRemote recovery is disabled for security.\n\nPlease visit a JPN Kiosk for biometric restoration."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Understood"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recovery")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _state == 0
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: _startRecovery,
                  child: const Text("REPORT LOST IC (Have Phone)")
              ),
              const SizedBox(height: 20),

              // --- BUTTON HIDDEN FOR NOW ---
              /*
              TextButton(
                onPressed: _showTotalLossHelp,
                child: const Text("I lost BOTH my Phone & IC", style: TextStyle(color: Colors.red)),
              )
              */
              // -----------------------------
            ],
          ),
        )
            : Column(
          children: [
            if (_hasPewaris) ...[
              const Text("Ask Pewaris to enter this code:", style: TextStyle(color: Colors.grey)),
              Text(_code, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, letterSpacing: 5)),
            ] else
              const Text("Verifying with Government Nodes...", style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),

            const SizedBox(height: 30),

            _row("Bank Node (RHB)", true),

            if (_hasPewaris)
              _row("Pewaris Guardian", _pewarisApproved)
            else
              Container(),

            _row("Govt Node (JPN)", true),

            if (_pewarisApproved) ...[
              const SizedBox(height: 30),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green)),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 40),
                      SizedBox(height: 10),
                      Text("IDENTITY RESTORED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text("A new key has been created", style: TextStyle(color: Colors.white)),
                    ],
                  )
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _row(String label, bool active) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListTile(
      tileColor: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(active ? Icons.check_circle : Icons.hourglass_top, color: active ? Colors.green : Colors.grey),
      title: Text(label, style: TextStyle(color: active ? Colors.green : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ),
  );
}

// ==========================================
// 8. SETTINGS SCREEN
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _icController = TextEditingController();
  String _selectedRelation = "Wife"; // Default value

  // List of options for the dropdown
  final List<String> _relations = ["Wife", "Husband", "Father", "Mother", "Child", "Sibling"];

  void _sendRequest() async {
    if (_icController.text.length < 6) return;
    final prefs = await SharedPreferences.getInstance();

    String target = _icController.text.replaceAll('-', '');
    String myIC = prefs.getString('userIC') ?? "Unknown";

    // 1. Send Request to Firebase with the SELECTED relationship
    await FirebaseDatabase.instance.ref("pewaris_requests/$target").set({
      "requesterName": "Ali Bin Ahmad",
      "requesterIC": myIC,
      "relation": _selectedRelation,
      "status": "pending"
    });

    // 2. Save TARGET ID and RELATION locally
    await prefs.setString('userPewaris', "Pending ($_selectedRelation)...");
    await prefs.setString('pending_pewaris_ic', target);
    await prefs.setString('pending_pewaris_relation', _selectedRelation);

    // 3. Update Global Notifier
    pewarisStatusNotifier.value = "Pending ($_selectedRelation)...";

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invite sent to $_selectedRelation!")));
      Navigator.pop(context); // Auto-close settings to show dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Dark Mode"),
            trailing: Switch(value: themeNotifier.value == ThemeMode.dark, onChanged: (val) => themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Pewaris (Guardian)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 15),

                // --- DROPDOWN MENU ---
                DropdownButtonFormField<String>(
                  value: _selectedRelation,
                  decoration: const InputDecoration(labelText: "Relationship", border: OutlineInputBorder()),
                  items: _relations.map((String val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRelation = val!),
                ),
                // -------------------------

                const SizedBox(height: 15),
                TextField(
                  controller: _icController,
                  decoration: const InputDecoration(labelText: "Pewaris IC Number", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendRequest,
                    icon: const Icon(Icons.send),
                    label: const Text("Send Invite"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4), foregroundColor: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Log Out", style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst)
          )
        ],
      ),
    );
  }
}