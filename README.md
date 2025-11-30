# Lynk

**Lynk** is a cross-platform file transfer application built with Flutter that enables direct peer-to-peer file sharing over a local network using raw socket connections. Users can send and receive files between devices by switching between **Server** and **Client** tabs within the app.

- The **Server tab** opens a socket and listens for incoming connections. When a client connects and sends a file, the server allows for saving the files to a desired directory.
- The **Client tab** allows the user to input the server's IP address, select a file, and send it directly.

Lynk is ideal for quick, local file transfers without relying on cloud services, internet access, or third-party tools.

---


### ⚠️ Notes
- Files are saved locally on the server device in a user defined directory.
- The app is designed for trusted local networks.
- Web is not supported due to limitations in Flutter's socket support for browsers.

---

## 🛠 Getting Started

### 📁 Clone the Repository

```bash
git clone https://github.com/joshk326/lynk.git
cd lynk
```

### 📦 Install Dependencies

```bash
flutter pub get
```

### 🚀 Run the App
```bash
flutter run
```

Launch the app on two devices (or emulators) on the same local network. Use the Server tab on one and the Client tab on the other. On the client device, enter the IP shown on the server tab, pick a file, and tap send. The file will be transmitted and stored on the server device.

---

### 💻 Platform Support
| Platform    | Status |
| -------- | :------: |
| Android  | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | ❌ |

---

### 📌 Roadmap
- ✅ ~~Change navigation for mobile devices~~
- ✅ ~~Add heartbeat to client to verify the server is still open~~
- ✅ ~~Add labels to tabs (Toggled in settings)~~
- Finish settings page (add default connects, default save path)
- ✅ ~~Transfer progress indicators~~
- improve mobile experience
- ✅ ~~End-to-end file encryption~~
- ✅ ~~Persistent transfer history Server Side~~
- ✅ ~~Save settings using SharedPrefs/json file~~
- Web support (create websocket)
