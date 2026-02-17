# SAPA HEBAT

**Siswa Aktif Peduli Alam Hidup Ekonomis Bersih Aman Tertib**

Aplikasi pembiasaan perilaku sehat untuk siswa yang terintegrasi dengan Guru dan Orang Tua. Dibangun menggunakan Flutter dan Firebase Cloud Firestore.

## Fitur Utama

### 1. Multi-Role Authentication

- **Siswa**: Login untuk mencatat aktivitas harian.
- **Guru**: Login untuk memverifikasi dan memonitor aktivitas siswa binaan.
- **Orang Tua**: Login untuk memantau perkembangan anak.

### 2. Dashboard Siswa

- **Rekap Harian**: Input 8 aktivitas wajib harian:
  - 🌅 **Bangun Pagi**: Pencatatan waktu bangun.
  - 📖 **Beribadah**: Checklist ibadah sesuai agama.
  - 🥗 **Makan Sehat**: Pencatatan pola makan bergizi.
  - 🏃 **Olahraga**: Pencatatan aktivitas fisik.
  - 🏫 **Sekolah**: Kehadiran dan aktivitas di sekolah.
  - 📚 **Gemar Belajar**: Pencatatan waktu belajar mandiri.
  - 👥 **Bermasyarakat**: Kegiatan sosial dan gotong royong.
  - 🌙 **Tidur Cepat**: Pencatatan waktu tidur.
- **Riwayat**: Melihat histori aktivitas yang sudah dilakukan.
- **Profil**: Informasi akun siswa.

### 3. Dashboard Guru

- **Verifikasi Aktivitas**: Memvalidasi (Approve/Reject) aktivitas harian siswa.
- **Monitoring**: Melihat rekapitulasi keaktifan siswa yang berada di bawah bimbingannya.
- **Manajemen Siswa**: Daftar siswa binaan (otomatis terelasi berdasarkan data seeding).

### 4. Dashboard Orang Tua

- **Monitoring Anak**: Memantau aktivitas harian anak yang terhubung dengan akun orang tua.
- **Laporan Harian**: Melihat detail kegiatan anak per hari.

## Teknologi yang Digunakan

- **Framework**: Flutter SDK (Min SDK: 3.10.8)
- **Database Backend**: Firebase Cloud Firestore
- **State Management**: Native Flutter `setState`
- **Other Libraries**:
  - `firebase_core`, `cloud_firestore`: Integrasi Firebase.
  - `firebase_messaging`: Notifikasi (Push Notifications).
  - `intl`: Formatting tanggal dan waktu.
  - `google_fonts`: Tipografi modern (Poppins).
  - `flutter_launcher_icons`: Icon aplikasi.

## Struktur Proyek

```
lib/
├── main.dart                          # Entry point
├── database/
│   └── database_helper.dart           # Logika Database (Firestore Logic)
├── screens/
│   ├── splash_screen.dart             # Layar awal
│   ├── login_siswa_screen.dart        # Login Siswa
│   ├── login_guru_screen.dart         # Login Guru
│   ├── login_ortu_screen.dart         # Login Orang Tua
│   ├── dashboard_screen.dart          # Dashboard Utama Siswa
│   ├── guru/                          # Modul Guru
│   │   ├── dashboard_guru_screen.dart
│   │   └── tabs/                      # Tab Verifikasi, Monitoring, Profil
│   ├── ortu/                          # Modul Orang Tua
│   │   ├── dashboard_ortu_screen.dart
│   │   └── tabs/                      # Tab Monitoring, Profil
│   ├── activities/                    # Form Input 8 Aktivitas
│   │   ├── bangun_pagi_screen.dart
│   │   ├── beribadah_screen.dart
│   │   └── ... (lainnya)
│   └── tabs/                          # Tab Umum (Beranda, Riwayat, Profil)
└── theme/
    └── app_theme.dart                 # Konfigurasi Tema Aplikasi
```

## Cara Menjalankan

1. **Persiapan**: Pastikan Flutter SDK sudah terinstall dan terkonfigurasi.

2. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**:
   - Pastikan file `firebase_options.dart` sudah ada (hasil setup `flutterfire configure`).
   - Pastikan koneksi internet aktif karena menggunakan database cloud.

4. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

## Akun Demo (Data Seeding)

Saat pertama kali dijalankan (jika disetup untuk seeding), aplikasi akan membuat data dummy sebagai berikut:

### 👨‍🏫 Guru (2 Akun)

Password default: `123456`

- `guru1` (ID: 101) - Mengelola Siswa 1-5
- `guru2` (ID: 102) - Mengelola Siswa 6-10

### 👨‍👩‍👧‍👦 Orang Tua (5 Akun)

Password default: `123456`

- `ortu1` (ID: 201) - Orang tua Siswa 1 & 2
- `ortu2` (ID: 202) - Orang tua Siswa 3 & 4
- `ortu3` (ID: 203) - Orang tua Siswa 5 & 6
- `ortu4` (ID: 204) - Orang tua Siswa 7 & 8
- `ortu5` (ID: 205) - Orang tua Siswa 9 & 10

### 🎓 Siswa (10 Akun)

Password default: `123456`

- `siswa1` s/d `siswa10` (ID: 301 - 310)

## Alur Data (Data Flow)

1. **Siswa** mengisi aktivitas di menu "Rekap Harian".
2. Data tersimpan di Firestore dengan status **"Pending"**.
3. **Guru** login dan melihat notifikasi/list verifikasi untuk siswa binaannya.
4. **Guru** melakukan validasi (data status berubah menjadi **"Verified"** atau **"Rejected"**).
5. **Orang Tua** dapat melihat status kegiatan anak secara real-time.

---

**Tugas Pengembangan Aplikasi Mobile (Team Project)**
