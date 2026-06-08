# JURNAL E-PKL: Implementasi Fitur Pop-up Notifikasi Top-up Approved & Rejected

**Nama**: Lucky Meirino Sany  
**Perusahaan**: PT. KyPay  
**Project**: KyPay Flutter Mobile Application  
**Fitur**: Pop-up Notifikasi Top-up (Approved & Rejected)  
**Tanggal**: Juni 2025

---

## 📋 Deskripsi Fitur

Fitur ini bertujuan untuk memberikan notifikasi real-time kepada user ketika admin melakukan approval atau rejection terhadap pengajuan top-up mereka. Sistem akan menampilkan pop-up dialog yang informatif untuk kedua kondisi tersebut. Ketika top-up disetujui, pop-up akan menampilkan notifikasi sukses lengkap dengan nominal, metode pembayaran, dan tombol "Lihat Struk" yang memungkinkan user melihat bukti transaksi mereka. Sementara ketika top-up ditolak, pop-up akan menampilkan notifikasi penolakan dengan alasan penolakan dari admin dan informasi untuk pengajuan ulang.

---

## 🔴 Kendala yang Dihadapi

### 1. Context & State Management Dalam Dialog Builder

Masalah utama yang dihadapi adalah ketika pop-up dialog ditampilkan, `context` yang diterima di dalam callback button berbeda dengan `context` parent karena dialog builder menghasilkan context baru. Hal ini menyebabkan ketika user klik tombol, reference ke state lama tidak valid. Dampaknya adalah Navigator.pop() tidak bekerja dengan benar, state tidak tersimpan dengan baik, dan button callback tidak bisa mengakses context yang tepat.

### 2. Dialog Menimpa Struk Modal

Ketika user mengklik tombol "Lihat Struk", struk modal muncul di atas pop-up sehingga keduanya saling menimpa. Ini membuat UI terlihat berantakan dan tidak profesional. Dampak dari masalah ini adalah user experience menjadi tidak smooth, struk dan pop-up tidak bisa dilihat dengan jelas secara bersamaan, dan navigation hierarchy tidak terstruktur dengan baik.

### 3. Pop-up Tidak Bisa Muncul Kembali

Setelah struk ditutup, pop-up tidak muncul lagi sehingga user harus refresh untuk melihat notifikasi lagi, atau pop-up menghilang begitu saja tanpa bisa dilihat kembali. Dampaknya adalah user bisa lupa sudah melihat notifikasi atau belum, informasi penting terlewat, dan user experience terganggu.

### 4. Tracking Duplicate Notifications

Sistem perlu tahu notifikasi mana yang sudah pernah dilihat user agar notifikasi tidak muncul berkali-kali di setiap refresh aplikasi. Masalah ini timbul karena SharedPreferences belum ter-setup dengan baik untuk tracking. Hasilnya adalah pop-up approved/rejected muncul berulang kali dan user bisa melihat notifikasi lama berkali-kali setiap kali membuka tab wallet.

### 5. Scope Issue di Try-Catch Block

Ketika menambahkan cek untuk `TopUpRejected`, variabel `prefs` dan `list` dideklarasikan di dalam try block, tetapi diakses di luar try block di rejected check section. Ini menyebabkan compilation error karena kedua variabel tersebut tidak terdefinisi di scope tersebut. Akibatnya adalah code tidak bisa berjalan, rejected check tidak berfungsi, dan aplikasi crash.

---

## ✅ Solusi yang Diterapkan

### 1. Simpan Context & State Sebelum Dialog

Solusi pertama adalah menyimpan reference context dan state sebelum dialog ditampilkan. Dengan cara ini, context tetap stabil sepanjang lifecycle dialog dan state tidak berubah ketika dialog ditampilkan. Button callback bisa mengakses context dan state yang benar tanpa khawatir terjadi perubahan atau reference yang tidak valid. Implementasinya adalah dengan membuat variabel lokal `savedContext` dan `savedState` yang menyimpan reference asli sebelum `showDialog()` dipanggil, kemudian menggunakan variabel-variabel tersebut di dalam dialog builder.

### 2. Gunakan Navigator.of(context, rootNavigator: true)

Menggunakan `Navigator.of(context, rootNavigator: true)` memastikan pop() bekerja dengan benar meskipun ada nested navigator dalam widget tree. Parameter `rootNavigator: true` ini crucial untuk mengatasi issue context yang berubah di dalam dialog builder. Dengan cara ini, pop-up bisa tertutup dengan benar tanpa terpengaruh oleh navigasi level yang lebih dalam, dan navigation hierarchy menjadi lebih stabil.

### 3. Implementasi Dialog Hierarchy

Solusi untuk masalah dialog yang saling menimpa adalah dengan mengimplementasikan dialog hierarchy yang proper. Ketika user klik tombol "Lihat Struk", pop-up dismiss sementara (dismiss popup), kemudian setelah delay 300ms untuk memastikan dialog benar-benar tertutup, struk modal ditampilkan. Setelah struk ditutup, pop-up akan muncul lagi secara otomatis menggunakan `.then()` callback. Dengan pendekatan ini, dialog tidak saling menimpa, UI lebih clean dan terstruktur, user bisa melihat struk tanpa gangguan, dan pop-up muncul lagi setelah struk ditutup dengan smooth animation.

### 4. Tracking dengan SharedPreferences

Untuk mengatasi masalah duplicate notifications, implementasi tracking dilakukan dengan menyimpan ID terakhir dari top-up yang sudah diapprove atau reject di SharedPreferences. Setiap kali sistem melakukan check, akan membandingkan ID top-up terbaru dengan ID yang tersimpan sebelumnya. Hanya top-up dengan ID yang lebih besar (lebih baru) yang akan menampilkan notifikasi. Setelah notifikasi ditampilkan, ID terbaru tersebut disimpan di SharedPreferences sehingga tidak akan muncul lagi di refresh berikutnya. Dengan tracking yang persistent ini, pop-up tidak muncul berkali-kali untuk notifikasi yang sama.

### 5. Pindahkan Cek Rejected ke Dalam Try Block

Solusi untuk scope issue adalah dengan memindahkan seluruh logika rejected check ke dalam try block yang sama dengan approved check. Dengan cara ini, variabel `prefs` dan `list` yang dideklarasikan di dalam try block tetap accessible untuk kedua cek (approved maupun rejected). Logic-nya dirancang agar jika ada approved top-up, system akan emit TopUpApproved dan return early. Jika tidak ada approved, maka system akan melanjutkan ke rejected check. Dengan struktur ini, scope issue teratasi, code lebih clean dan maintainable, dan error compilation hilang.

---

## 🎯 Implementasi Teknis

Implementasi fitur ini melibatkan modifikasi pada beberapa file dalam project Flutter. Pertama, file `lib/blocs/topup/topup_event.dart` ditambahkan dengan `CheckApprovedTopUp event` untuk trigger pengecekan top-up yang baru diapprove. Kedua, file `lib/blocs/topup/topup_state.dart` ditambahkan dengan dua state baru yaitu `TopUpApproved state` dan `TopUpRejected state` untuk merepresentasikan kedua kondisi tersebut.

Ketiga, file `lib/blocs/topup/topup_bloc.dart` adalah file yang paling signifikan dimodifikasi karena di sini ditambahkan method `_onCheckApproved()` dengan dual logic untuk mengecek kedua status top-up (approved dan rejected) serta integrasi dengan SharedPreferences untuk tracking notification yang sudah dilihat user. Keempat, file `lib/blocs/wallet/wallet_event.dart` dimodifikasi sehingga `FetchWallet` event menerima optional `TopUpBloc` parameter untuk memungkinkan wallet bloc mengakses top-up bloc. Kelima, file `lib/blocs/wallet/wallet_bloc.dart` dimodifikasi pada method `_onFetchWallet()` sehingga setelah wallet berhasil dimuat, system akan trigger `CheckApprovedTopUp` event di TopUpBloc.

Terakhir, file `lib/screens/wallet/wallet_screen.dart` mengalami perubahan signifikan dengan modifikasi MultiBlocListener untuk listen TopUpBloc state, penambahan dua methods besar yaitu `_showTopUpApprovedPopup()` dan `_showTopUpRejectedPopup()`, serta update pada FetchWallet calls di initState dan _onRefresh method untuk mempassing topUpBloc parameter.

---

## 📊 Flow Diagram

### Approved Pop-up Flow

Flow untuk menampilkan approved pop-up dimulai dari Wallet Screen yang melakukan FetchWallet dengan parameter topUpBloc. Kemudian WalletBloc menerima event FetchWallet dan setelah berhasil fetch data wallet, system emit WalletLoaded state. Di dalam handler FetchWallet, WalletBloc menambahkan CheckApprovedTopUp event ke TopUpBloc. TopUpBloc menerima event tersebut dan melakukan fetch ke endpoint /topup/ untuk mendapatkan daftar top-up user, kemudian mengecek status 'approved'. Jika ditemukan top-up dengan status approved yang belum pernah dilihat user (ID lebih besar dari last_seen_approved_topup_id di SharedPreferences), TopUpBloc emit TopUpApproved state. Akhirnya, WalletScreen yang melisten TopUpBloc state akan menangkap TopUpApproved dan memanggil _showTopUpApprovedPopup() untuk menampilkan dialog dengan nominal, metode pembayaran, dan tombol-tombol yang relevan.

### Interaction Flow - Lihat Struk

Ketika user mengklik tombol "Lihat Struk" dalam pop-up approved, langkah pertama adalah pop-up akan dismiss menggunakan Navigator.pop(). Kemudian system menunggu 300 millisecond menggunakan Future.delayed untuk memastikan pop-up sudah benar-benar tertutup. Setelah delay tersebut, showStrukModal() dipanggil untuk menampilkan modal struk dengan StrukWidget yang berisi informasi detail transaksi top-up. User dapat melihat struk secara detail. Ketika user mengklik X atau tutup button di pojok kanan atas modal struk, modal tertutup dan .then() callback dijalankan. Callback ini memanggil _showTopUpApprovedPopup() kembali sehingga pop-up approved muncul lagi di screen. Dengan flow ini, user dapat melihat struk tanpa pop-up mengganggu, dan setelah selesai melihat struk, pop-up tetap ada untuk user klik OK.

---

## 📈 Learning & Insights

Selama proses implementasi fitur ini, banyak hal penting yang dipelajari tentang Flutter development. Pertama, Context Management dalam Dialog adalah hal crucial karena context yang diterima di dalam dialog builder berbeda dengan parent context. Penting untuk menyimpan reference context sebelum dialog ditampilkan agar dapat mengaksesnya dengan benar di callback. Kedua, Navigator Hierarchy dengan penggunaan `rootNavigator: true` sangat penting untuk nested navigation scenarios dan memastikan pop() bekerja dengan baik di berbagai tingkat navigasi.

Ketiga, Async Callback Pattern menggunakan `.then()` adalah cara elegans untuk menunggu sampai dialog/modal tertutup sebelum menampilkan UI selanjutnya, sehingga memberikan experience yang smooth dan terstruktur. Keempat, SharedPreferences Tracking adalah cara efektif dan efficient untuk melacak state yang persistent di level device, memungkinkan aplikasi untuk mengingat informasi bahkan setelah aplikasi ditutup dan dibuka kembali.

Dari sisi implementation, Best Practice yang diterapkan mencakup Separation of Concerns di mana BLoC handling semua logic dan UI layer hanya handling display. Selain itu, digunakan proper error handling dengan try-catch untuk silent fail agar tidak mengganggu user experience, proper async/await pattern untuk semua async operations, dan widget composition untuk membuat reusable UI components yang maintainable. Semua praktik ini berkontribusi pada code quality yang lebih baik dan aplikasi yang lebih robust.

---

## 🔧 Testing & Validation

Untuk memastikan fitur berfungsi dengan baik, dilakukan testing menyeluruh pada berbagai skenario. Pertama, test menunjukkan bahwa pop-up muncul dengan benar ketika top-up diapprove oleh admin. Kedua, pop-up juga muncul dengan benar ketika top-up direjek beserta alasan penolakan dari admin. Ketiga, system berhasil mencegah pop-up muncul berkali-kali untuk notifikasi yang sama melalui tracking dengan SharedPreferences.

Keempat, struk dapat dibuka melalui tombol "Lihat Struk" dan ditutup tanpa merusak UI atau state aplikasi. Kelima, pop-up muncul lagi secara otomatis setelah struk ditutup, memberikan experience yang seamless kepada user. Terakhir, tombol OK di pop-up dapat menutup pop-up dengan benar menggunakan Navigator yang tepat. Semua test cases ini passed dan memastikan bahwa implementasi fitur telah memenuhi requirements dan tidak ada regression pada functionality yang sudah ada.

---

## 📝 Kesimpulan

Implementasi fitur pop-up notifikasi top-up approved dan rejected telah berhasil diselesaikan dengan menggunakan solid architecture berbasis BLoC pattern. Fitur ini memberikan solusi komprehensif untuk berbagai kendala yang dihadapi, mulai dari context management, dialog hierarchy, duplicate notification tracking, hingga proper scope management.

Sistem yang dibangun memiliki UX yang smooth di mana user dapat melihat notifikasi real-time ketika ada perubahan status top-up mereka. Dialog yang dirancang dengan baik tidak saling menimpa, dan user dapat melihat struk tanpa meninggalkan pop-up notification. Dengan implementasi tracking yang persistent menggunakan SharedPreferences, notification tidak muncul berkali-kali dan system dapat mengingat state user dalam jangka panjang.

Fitur ini memberikan feedback real-time kepada user ketika ada perubahan status top-up, meningkatkan user experience dan transparency dalam proses top-up di aplikasi KyPay. User dapat dengan mudah memahami status pengajuan mereka dan mengambil tindakan selanjutnya, baik itu melihat struk untuk approved top-up atau mengajukan ulang untuk rejected top-up. Implementasi ini juga membuka peluang untuk pengembangan fitur serupa di bagian lain dari aplikasi, membuat KyPay semakin responsif dan user-friendly.

