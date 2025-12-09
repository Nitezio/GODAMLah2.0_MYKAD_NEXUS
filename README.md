# MyKad Nexus 🛡️
> Decentralizing Malaysia's Identity Infrastructure. The Plastic Card is the Key; The Phone is the Bridge.

## 🏆 GODAM Hackathon 2025 - Security Track
**Team:** [Your Team Name]
**Status:** Working Prototype (Round 1)

---

## 📖 The Problem
Centralized databases create "Honeypots" for hackers. Citizens have no control over who keeps their data after filling out manual forms.

## 💡 The Solution
**MyKad Nexus** creates a federated identity layer:
1.  **Passive Key:** Uses the existing MyKad NFC chip for offline authentication.
2.  **Digital Bridge:** The mobile app fetches encrypted data from separate nodes (JPN, MoH, Bank).
3.  **Zero-Persistence:** Data is transferred securely to the service provider and never stored on the phone.

---

## ⚙️ Technical Architecture (Feasibility)
We utilize a **Federated Node Simulation** for this prototype:
* **Frontend:** Flutter (Dart) for cross-platform mobile support.
* **NFC:** `nfc_manager` plugin to interface with ISO 14443 chips.
* **Backend:** Firebase Firestore (Simulating 3 distinct nodes: `node_jpn`, `node_moh`, `node_bank`).
* **Handshake:** QR Code JSON payload for session initiation.

---

## 📱 Screens & Features
| **Granular Consent** | **Audit Trail** | **Social Recovery** |
|:---:|:---:|:---:|
| [Insert Screenshot 1] | [Insert Screenshot 2] | [Insert Screenshot 3] |
| User approves specific data fields. | Permanent log of who accessed data. | Restore ID via trusted shards. |

---

## 🚀 How to Run the Prototype
1. Clone the repo:
   `git clone https://github.com/yourusername/mykad-nexus.git`
2. Install dependencies:
   `flutter pub get`
3. Run on Android Device (NFC Required):
   `flutter run`

---

## 🎥 Demo Video
[Link to YouTube/Drive Video]
