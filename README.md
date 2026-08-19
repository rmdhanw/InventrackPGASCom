# 📦 Inventrack PGASCom

![Flutter](https://img.shields.io/badge/Flutter-3.6+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-4CAF50?style=for-the-badge)

**Inventrack** adalah aplikasi mobile berbasis Flutter yang dirancang khusus untuk memenuhi kebutuhan operasional **PGASCom** dalam mengelola sistem inventaris barang dan pengajuan kendaraan operasional (*carpool*). 

Aplikasi ini dibangun menggunakan prinsip **Clean Architecture**, **BLoC Pattern** untuk state management, dan diintegrasikan dengan **Firebase Services** serta notifikasi otomatis ke **Telegram Bot**.

---

## ✨ Fitur Utama

### 🔐 1. Autentikasi & Manajemen Pengguna
- **Login & Register:** Akses aman pengguna dengan verifikasi Firebase Authentication.
- **Peran Pengguna (*User Roles*):** Manajemen hak akses berbasis peran (`User`, `Admin`, `Superadmin`).

### 📑 2. Manajemen Inventaris (*Inventory Management*)
- **Pencatatan Barang:** Tambah, edit, dan hapus barang inventaris secara individu maupun *batch write*.
- **Pelacakan Transaksi:** Lacak riwayat masuk/keluar barang berdasarkan nomor serial barang.
- **Kategori Efisien:** Pemfilteran kategori barang cepat yang dioptimalkan dengan sistem *metadata caching* untuk mengurangi read operasi Firestore.

### 🚗 3. Operasional Carpool (*Carpool & Vehicle Request*)
- **Pengajuan Permintaan Carpool:** Formulir pendaftaran dan pengajuan permintaan kendaraan operasional.
- **Status Pengemudi & Jarak Tempuh:** Pantau status driver, jadwal jam berangkat/kembali, dan kilometer (KM) awal/akhir.
- **Notifikasi Telegram Otomatis:** Setiap kali permintaan carpool diajukan, sistem secara otomatis mengirimkan pesan notifikasi ke grup Telegram operasional.

---

## 🏗️ Arsitektur Aplikasi (Clean Architecture)

Proyek ini mengadopsi standar **Clean Architecture** (Dependency Inversion) untuk memisahkan tanggung jawab kode secara tegas (*Separation of Concerns*):

```text
lib/
├── core/                       # Utility, Error Failures & Firestore Constants
├── domain/                     # Pure Business Logic (Entities & Repository Interfaces)
│   ├── entities/               # User, Inventory, Carpool Entities
│   └── repositories/           # Abstract Repository Contracts
├── data/                       # Data Sources, Models (DTO), & Repository Implementations
│   ├── datasources/            # Firebase Auth, Firestore, & Telegram API Clients
│   ├── models/                 # Model Mappers (JSON/Firestore to Domain Entity)
│   └── repositories/           # Repository Implementations (with In-Memory Caching)
├── presentation/               # UI Layer (Screens, Widgets, & BLoCs)
│   ├── bloc/                   # State Management (Auth, Inventory, Carpool)
│   ├── routes/                 # GoRouter Navigation Config
│   └── screens/                # UI Screens & Layouts
└── main.dart                   # Application Entry Point & Dependency Injection
```

---

## 🛠️ Teknologi yang Digunakan

* **Framework:** [Flutter](https://flutter.dev/) (Dart SDK `^3.6.2`)
* **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) & [equatable](https://pub.dev/packages/equatable)
* **Backend Services:** `firebase_core`, `firebase_auth`, `cloud_firestore`
* **Routing:** [go_router](https://pub.dev/packages/go_router)
* **Local Storage & Security:** `shared_preferences`, `flutter_secure_storage`
* **Notifikasi:** Telegram Bot API via `http` client

---

## 🚀 Panduan Penggunaan & Instalasi

### Prasyarat
- Flutter SDK `^3.6.2` atau versi lebih baru
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Akun Firebase (jika ingin menghubungkan ke proyek Firebase sendiri)

### 1. Clone Repositori
```bash
git clone https://github.com/rmdhanw/InventrackPGASCom.git
cd InventrackPGASCom
```

### 2. Install Dependensi
```bash
flutter pub get
```

### 3. Konfigurasi Environment Variables
Salin file template `.env.example` ke `.env` untuk keperluan pengujian lokal:
```bash
cp .env.example .env
```
Isi file `.env` dengan kredensial bot Telegram Anda:
```env
TELEGRAM_BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_TELEGRAM_CHAT_ID
```

### 4. Jalankan Aplikasi
Jalankan aplikasi di emulator atau perangkat fisik menggunakan `--dart-define`:
```bash
flutter run --dart-define=TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN" --dart-define=TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
```

---

## 🔒 Keamanan (Security Best Practices)

- File sensitif seperti `.env`, `key.properties`, `google-services.json`, dan `GoogleService-Info.plist` secara otomatis diabaikan oleh Git via `.gitignore`.
- Seluruh API Token dan Kredensial tidak di-*hardcode* di dalam berkas Dart source code.

---

## 📄 Lisensi

Hak Cipta © 2026 **Inventrack PGASCom**.
