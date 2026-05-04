# 📔 JURNAL E-PKL (Elektronik Praktik Kerja Lapangan)

**Nama Program:** KyPay - Aplikasi Mobile Dompet Digital  
**Platform:** Flutter (Android)  
**Periode:** Mei 2026  
**Topik Utama:** Debug Avatar Profil & Testing Multi-Device

---

## 📋 RINGKASAN AKTIVITAS

Pada periode ini, tim melakukan debugging mendalam pada fitur avatar profil dan melakukan pengujian aplikasi pada 2 perangkat fisik secara bersamaan. Terdapat beberapa kendala teknis yang berhasil diidentifikasi dan diselesaikan.

---

## 🔴 KENDALA 1: Avatar Tidak Tampil di Halaman Profil (Mobile)

### **Uraian Kendala**
Avatar berhasil di-upload dan terlihat di web dashboard, namun di aplikasi mobile (edit profile & profile screen), avatar hanya menampilkan inisial (default avatar). Masalah ini terjadi karena beberapa faktor: URL format tidak sesuai backend, field avatar tidak terupdate saat simpan perubahan, dan setelah upload avatar dipanggil `CheckAuthStatus()` yang memanggil `/verify_token` sehingga token dianggap invalid dan terjadi logout otomatis.

### **Solusi yang Diterapkan**
Membuat event baru `UpdateUserData` di Auth BLoC untuk update user state tanpa perlu re-verify token. Mengganti `CheckAuthStatus()` dengan `UpdateUserData()` di method `_pickAndUploadAvatar()` dan `_save()`, sehingga avatar langsung terupdate dari response API tanpa risiko logout. Memperbaiki `UserModel.avatarUrl` getter untuk mengenali format `/uploads/avatars/` yang digunakan backend. Field avatar di UserModel juga dipastikan menggunakan field asli (bukan getter `avatarUrl`) saat create UserModel baru di `_save()` method.

**Hasil:** Avatar muncul instant setelah upload, profile update tidak menghapus avatar, dan konsisten di semua halaman.

---

## 🔴 KENDALA 2: Avatar Tidak Tampil di Halaman Kontak

### **Uraian Kendala**
Halaman Kontak menampilkan user list dengan avatar seharusnya muncul, tetapi hanya menampilkan inisial. Penyebabnya adalah backend awalnya mengirim full URL dengan domain `localhost` (e.g., `http://localhost:8000/storage/abc123.jpg`). Ketika app running di mobile device fisik, `localhost` tidak bisa diakses karena hanya valid di PC lokal. Diperlukan IP address untuk akses backend dari device, namun backend hard-coded domain sehingga URL menjadi invalid untuk multi-device testing.

### **Solusi yang Diterapkan**
Backend team mengubah response `/contacts` endpoint untuk mengirim relative path (e.g., `/uploads/avatars/abc123.jpg`) alih-alih full URL. Di Flutter, dibuat fungsi `_buildAvatarUrl()` di ContactScreen untuk membangun URL lengkap dari relative path dengan cara menggabungkan IP address backend dari `ApiService.baseUrl` dengan path yang diterima dari response. Fungsi ini juga menangani fallback untuk berbagai format response (full URL, relative path, atau hanya filename).

**Hasil:** Avatar di halaman Kontak muncul dengan benar dan bisa support multi-device dengan IP berbeda.

---

## 🟡 KENDALA 3: Testing di 2 HP Fisik Secara Bersamaan

### **Uraian Kendala**
Ingin testing aplikasi di 2 HP fisik sekaligus, namun HP 1 error/tidak bisa login padahal HP 2 lancar. Awalnya menjalankan `flutter run` tanpa spesifik device, sistem tidak tahu device mana yang dituju. Selain itu, dikonfigurasi `API_HOST` berbeda untuk kedua HP (192.168.112.16 dan 192.168.112.26), padahal backend hanya running di satu IP saja. User juga kebingungan apakah perlu menjalankan 2 backend instance.

### **Solusi yang Diterapkan**
Mengidentifikasi device ID dari masing-masing HP dengan perintah `flutter devices`. Menentukan backend IP yang benar dengan melihat `ipconfig` dan menemukan IPv4 Address yang aktif di jaringan WiFi. Menjalankan kedua HP dengan API_HOST yang sama (IP backend yang benar) menggunakan device ID explicit di command line. Backend tetap running 1 instance saja yang accessible oleh kedua device.

**Hasil:** Kedua HP bisa running bersamaan dan bisa login serta akses backend. Backend cukup 1 instance, dan bisa test fitur di 2 device sekaligus dengan hot reload.

---

## 📊 RINGKASAN PERBAIKAN

| Aspek | Sebelum | Sesudah |
|-------|---------|---------|
| **Avatar Profile** | ❌ Tidak muncul | ✅ Muncul instant |
| **Logout Masalah** | ❌ Logout setelah update | ✅ Tetap login |
| **Avatar URL Format** | ❌ `/storage/` (salah) | ✅ `/uploads/avatars/` (benar) |
| **Contact Avatar** | ❌ Hanya inisial | ✅ Foto muncul |
| **Multi-Device Test** | ❌ HP 1 error | ✅ Kedua HP berfungsi |

---

## 💡 PEMBELAJARAN KUNCI

1. **Konsistensi Backend-Frontend**: URL format antara backend & frontend harus match untuk menghindari image loading error
2. **Relative Path Lebih Fleksibel**: Relative path lebih baik daripada full URL untuk support multi-environment (localhost, IP, domain)
3. **Hindari Token Reverification**: Jangan reverify token setelah update, gunakan data dari response API langsung untuk update state
4. **Multi-Device Setup**: Semua device harus akses backend di IP yang sama untuk menghindari connection error
5. **Debug dengan Logging**: Print response data dan event logging membantu troubleshoot format mismatch dengan cepat

---

**Status:** ✅ **COMPLETED**  
**Tanggal Selesai:** 4 Mei 2026  
**Total Waktu Debugging:** ~2 jam  
**Issues Fixed:** 3 major issues  

---

*Jurnal ini dibuat sebagai dokumentasi proses debugging dan pembelajaran selama periode E-PKL.*
