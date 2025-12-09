import 'dart:async';

/// This service simulates the "Switchboard" architecture.
/// In a real production environment, these would be secure API calls
/// to encrypted Government (JPN) and Health (MoH) endpoints.

class FederatedNodeService {

  // Simulate fetching Identity Data from National Registration Dept (JPN)
  Future<Map<String, String>> fetchJPNData(String icNumber) async {
    // Simulate network latency (The "Handshake")
    await Future.delayed(const Duration(milliseconds: 1500));

    // Return Mock Data (Data at Source)
    return {
      "source": "JPN_SECURE_NODE_01",
      "name": "ALI BIN AHMAD",
      "ic": "880505-10-5555",
      "address": "123 JALAN INNOVATION, CYBERJAYA",
      "status": "VERIFIED_ACTIVE"
    };
  }

  // Simulate fetching Health Data from Ministry of Health (MoH)
  Future<Map<String, String>> fetchMoHData(String icNumber) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    return {
      "source": "MOH_SECURE_DB_09",
      "blood_type": "O+",
      "allergies": "PENICILLIN, PEANUTS",
      "vaccination": "FULLY_VACCINATED"
    };
  }

  // The "Kill Switch" - Wipes data after transfer
  void wipeSessionData() {
    print("SECURE PROTOCOL: Local RAM cleared. No data persisted.");
  }
}