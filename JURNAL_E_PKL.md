# 📔 JURNAL E-PKL (Elektronik Praktik Kerja Lapangan)

**Nama Program:** KyPay - Aplikasi Mobile Dompet Digital  
**Platform:** Flutter (Android)  
**Periode:** Mei 2026

---

## RINGKASAN AKTIVITAS PERIODE 1 (1-4 Mei 2026)

Pada minggu pertama, tim melakukan debugging mendalam pada fitur avatar profil di aplikasi mobile KyPay. Avatar berhasil di-upload ke server dan terlihat di web dashboard, namun tidak muncul di aplikasi mobile. Masalah ini terjadi karena beberapa faktor teknis yang perlu diidentifikasi dan diselesaikan. Selain itu, dilakukan juga pengujian aplikasi pada 2 perangkat fisik secara bersamaan untuk memastikan konsistensi data dan performa di multiple devices.

### KENDALA 1: Avatar Tidak Tampil di Halaman Profil (Mobile)

Avatar berhasil di-upload dan terlihat di web dashboard, namun di aplikasi mobile pada halaman edit profile dan profile screen, avatar hanya menampilkan inisial berdasarkan nama user (default avatar). Penyebab utama adalah format URL avatar tidak sesuai dengan struktur backend, field avatar tidak terupdate dengan benar saat melakukan simpan perubahan profil, dan setelah proses upload avatar, aplikasi memanggil `CheckAuthStatus()` yang kemudian memanggil endpoint `/verify_token`. Endpoint ini ternyata mengembalikan respon yang invalid sehingga token dianggap tidak valid dan menyebabkan logout otomatis.

Solusi yang diterapkan adalah dengan membuat event baru bernama `UpdateUserData` di dalam Auth BLoC untuk melakukan update state user tanpa perlu melakukan reverification token. Selanjutnya mengganti pemanggilan `CheckAuthStatus()` dengan `UpdateUserData()` di dalam method `_pickAndUploadAvatar()` dan `_save()`, sehingga avatar dapat langsung terupdate dari response API tanpa risiko logout yang tidak diinginkan. Perbaikan juga dilakukan pada `UserModel.avatarUrl` getter untuk memastikan dapat mengenali format path `/uploads/avatars/` yang digunakan oleh backend. Field avatar di UserModel juga dipastikan menggunakan field asli dan bukan getter `avatarUrl` saat membuat UserModel baru di method `_save()`.

Hasil dari solusi ini adalah avatar muncul instant setelah proses upload, profile update tidak lagi menghapus avatar yang sudah ada, dan avatar tampil konsisten di semua halaman aplikasi.

### KENDALA 2: Avatar Tidak Tampil di Halaman Kontak

Halaman Kontak seharusnya menampilkan daftar user dengan avatar mereka, namun hanya menampilkan inisial nama user. Penyebab masalah ini adalah backend awalnya mengirimkan full URL lengkap dengan domain `localhost` pada response (contoh: `http://localhost:8000/storage/abc123.jpg`). Ketika aplikasi berjalan di perangkat mobile fisik, localhost tidak bisa diakses karena hanya valid di PC lokal. Untuk mengakses backend dari device fisik diperlukan IP address, namun backend telah hard-coded domain sehingga URL menjadi invalid untuk pengujian multi-device.

Solusi yang diterapkan adalah dengan meminta backend team untuk mengubah format response endpoint `/contacts` agar mengirimkan relative path saja (contoh: `/uploads/avatars/abc123.jpg`) alih-alih full URL lengkap. Di sisi Flutter, dibuat fungsi helper bernama `_buildAvatarUrl()` di ContactScreen untuk membangun URL lengkap dari relative path dengan cara menggabungkan IP address backend yang diperoleh dari `ApiService.baseUrl` dengan path yang diterima dari response API. Fungsi ini juga dilengkapi dengan fallback untuk menangani berbagai format response yang mungkin diterima seperti full URL, relative path, atau hanya filename saja.

Hasil dari implementasi ini adalah avatar di halaman Kontak muncul dengan benar dan aplikasi dapat mendukung multi-device testing dengan IP backend yang berbeda-beda.

### KENDALA 3: Testing di 2 HP Fisik Secara Bersamaan

Terjadi kendala saat melakukan testing aplikasi di 2 HP fisik sekaligus. HP pertama mengalami error dan tidak bisa login padahal HP kedua berjalan lancar tanpa masalah. Awalnya command `flutter run` dijalankan tanpa menspesifik device target, sehingga sistem tidak tahu device mana yang seharusnya menerima build. Selain itu, dikonfigurasi `API_HOST` berbeda untuk kedua HP dengan IP 192.168.112.16 dan 192.168.112.26, padahal backend hanya running di satu IP saja. User juga merasa kebingungan apakah perlu menjalankan 2 instance backend yang terpisah.

Solusi yang diterapkan adalah dengan mengidentifikasi device ID dari masing-masing HP menggunakan perintah `flutter devices` untuk melihat daftar device yang terhubung. Selanjutnya menentukan backend IP yang benar dengan melihat output `ipconfig` dan menemukan IPv4 Address yang aktif di jaringan WiFi yang sama. Kemudian menjalankan kedua HP dengan API_HOST yang sama (IP backend yang benar) menggunakan device ID explicit dalam command line flutter run. Backend tetap running 1 instance saja yang dapat diakses oleh kedua device sekaligus.

Hasil dari solusi ini adalah kedua HP dapat berjalan bersamaan dan dapat login serta mengakses backend dengan normal. Backend cukup 1 instance saja tanpa perlu duplikasi, dan testing fitur dapat dilakukan di 2 device secara bersamaan dengan hot reload yang responsif.

---

## RINGKASAN AKTIVITAS PERIODE 2 (5-6 Mei 2026)

Pada periode kedua, tim menghadapi masalah teknis yang lebih kompleks saat proses upload avatar di device Android fisik. Error `ImageDecoder$DecodeException` terjadi saat sistem Android mencoba melakukan decode terhadap image yang di-upload dari gallery. Selain itu, avatar juga tidak tampil di mobile meskipun file sudah berhasil terupload ke server, karena response dari endpoint `/verify_token` belum lengkap dan tidak mengandung field avatar. Dilakukan investigasi mendalam pada kedua sisi (client dan server) untuk mengidentifikasi root cause dan mengimplementasikan solusi yang optimal.

### KENDALA 1: Android ImageDecoder Error saat Upload Avatar

Ketika user melakukan upload avatar dari gallery di device Android, error muncul dengan pesan `E/FlutterJNI: Failed to decode image` disertai dengan `android.graphics.ImageDecoder$DecodeException`. Error ini terjadi karena beberapa alasan teknis. Pertama, image picker di Flutter tidak selalu melakukan konversi ke format yang kompatibel dengan semua versi Android, format HEIC dan WebP khususnya tidak didukung oleh Android versi lama. Kedua, server menyimpan file image tanpa melakukan proses re-encode, sehingga format file dapat menjadi corrupt atau tidak valid. Ketiga, Android ImageDecoder tidak dapat menangani file dengan format atau codec yang tidak standard dan non-compatible.

Solusi yang diterapkan dimulai dari sisi client dengan mengganti package `flutter_image_compress` yang sebelumnya digunakan dengan built-in compression yang ada di `image_picker` karena built-in compression terbukti lebih reliable dan stabil. Parameter `imageQuality` diturunkan dari nilai 85 menjadi 75, dan kemudian dioptimasi lagi menjadi 60 untuk memastikan kompatibilitas maksimal dengan device lama. Nilai `maxWidth` dan `maxHeight` juga diturunkan dari 1024 menjadi 800 untuk mengurangi kompleksitas file. Penambahan penting adalah explicit `Authorization` header saat melakukan upload FormData karena FormData tidak secara otomatis membawa authorization header dari interceptor.

Implementasi code di client side adalah sebagai berikut: image picker dikonfigurasi dengan `maxWidth: 800`, `maxHeight: 800`, dan `imageQuality: 60`. Saat melakukan POST request dengan FormData, ditambahkan options dengan explicit Authorization header yang berisi token dari `ApiService.getToken()`. Ini memastikan bahwa server dapat mengidentifikasi user yang melakukan upload.

Di sisi server, diperlukan implementasi validasi dan processing yang proper. Server harus melakukan re-encode setiap image yang di-upload ke format JPEG standard sebelum menyimpan file. Validasi MIME type harus dilakukan untuk hanya menerima `image/jpeg` dan `image/png`. Image harus dikonversi ke mode RGB dan menghilangkan alpha channel untuk format JPEG. Dimensi maksimal dibatasi pada 1024x1024 pixel dengan kualitas 85 untuk mempertahankan keseimbangan antara ukuran file dan kualitas visual.

Contoh implementasi server side menggunakan Python dengan library Pillow adalah: ketika file diterima, dilakukan opening dengan Image.open(), konversi ke RGB mode, dan kemudian disimpan kembali dalam format JPEG dengan quality 85. Dengan implementasi ini, hasil akhirnya adalah upload avatar berhasil tanpa error, Android dapat melakukan decode image dengan baik, dan tidak ada lagi error berkaitan dengan file yang corrupt.

### KENDALA 2: Avatar Tidak Muncul di Mobile Karena Response Incomplete

Meskipun file avatar sudah tersimpan dengan benar di server dan terlihat pada web dashboard, avatar tidak muncul di aplikasi mobile. Di mobile hanya ditampilkan inisial user sebagai fallback default avatar. Penyebab utama masalah ini adalah response yang dikirim oleh endpoint `/verify_token` tidak lengkap. Response hanya berisi informasi sukses dengan pesan token valid, tetapi tidak mengandung data user yang lengkap, khususnya field `avatar`. Ketika `UserModel` di-parse dari response yang incomplete ini, field avatar menjadi null dan avatar tidak dapat ditampilkan.

Solusi di sisi client adalah dengan menambahkan `debugPrint` di dalam method `avatarUrl` getter untuk memantau URL yang digenerate dan membantu proses debugging. Memastikan bahwa parsing dari response endpoint `/verify_token` dilakukan dengan benar dan dilengkapi dengan error handling yang robust untuk menangani berbagai format response yang mungkin diterima.

Implementasi code mencakup method `avatarUrl` getter yang pertama mengecek apakah avatar null atau kosong, jika iya maka return null. Jika avatar sudah berisi full URL (dimulai dengan http), langsung return URL tersebut. Jika bukan, maka dibangun base URL dari `ApiService.baseUrl` dengan mengganti `/api` menjadi `/storage/`. URL lengkap kemudian digenerate dengan menggabungkan base URL dan avatar path, lalu di-print menggunakan `debugPrint` untuk logging.

Di sisi server, perbaikan yang paling critical adalah endpoint `/api/verify_token` harus dirubah untuk mengembalikan full user object, format yang sama dengan response endpoint `/login`. Response harus mencakup semua field yang diperlukan oleh UserModel termasuk id, name, email, phone, avatar, role, api_token, job_title, company, dan bio.

Format response yang diharapkan adalah JSON object yang berisi semua field user tersebut. Avatar field harus berisi relative path ke file image seperti `avatars/2026-04-30-xxx.jpg` bukan full URL. Dengan perubahan ini di server side, hasil akhirnya adalah avatar field menjadi populated dengan benar setelah app melakukan verify token, dan avatar dapat ditampilkan di mobile dengan benar.

---

## PEMBELAJARAN KUNCI DAN INSIGHTS

Dari proses debugging dan troubleshooting yang telah dilakukan, terdapat beberapa pembelajaran penting yang dapat diambil untuk pengembangan project ke depannya. Pertama, mengenai image compatibility, kompresi yang aggressive dengan quality 60 terbukti lebih penting dibanding menjaga visual quality untuk mencegah decode error di Android device lama. Trade-off antara ukuran file dan kompatibilitas perlu dipertimbangkan dengan matang.

Kedua, mengenai validasi di server side, image upload harus selalu di-validate dan di-re-encode di server side, bukan hanya mengandalkan validasi di client side. Server adalah gatekeeper terakhir dan bertanggung jawab penuh untuk memastikan file yang disimpan adalah valid dan bisa diakses oleh client. Ketiga, response consistency adalah kunci, endpoint yang mengembalikan user data harus konsisten dalam struktur user object yang dikembalikan untuk menghindari confusion dan parsing error.

Keempat, mengenai authorization headers, FormData upload memerlukan explicit Authorization header dalam options request karena tidak akan secara otomatis inherit dari interceptor Dio yang sudah di-setup. Hal ini penting untuk memastikan server dapat mengidentifikasi user yang melakukan upload. Kelima, logging dan debugging tools seperti `debugPrint` sangat membantu dalam tracing issue, terutama saat menghadapi URL generation dan format mismatch yang sulit di-debug tanpa visibility ke dalam proses.

---

**Status:** ✅ **COMPLETED**  
**Total Periode:** 6 hari (1-6 Mei 2026)  
**Total Waktu Debugging:** ~6 jam  
**Issues Fixed:** 5 major issues  
**Teknologi yang Digunakan:** Flutter, Dio, BLoC Pattern, Image Picker, FormData  

---

*Jurnal ini dibuat sebagai dokumentasi komprehensif dari proses debugging, troubleshooting, dan pembelajaran selama periode E-PKL untuk project KyPay.*
