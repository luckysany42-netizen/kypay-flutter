import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // Index FAQ yang sedang dibuka (-1 = semua tutup)
  int _openIndex = -1;

  final List<_FaqItem> _faqs = [
    _FaqItem(
      category: 'Akun & Keamanan',
      icon: Icons.person_outline,
      color: Color(0xFF1a56db),
      question: 'Bagaimana cara mengubah PIN KyPay saya?',
      answer:
          'Saat ini PIN KyPay diatur saat pertama kali mendaftar. Untuk mengubah PIN, '
          'kamu bisa menghubungi tim support kami atau menunggu fitur ubah PIN '
          'yang akan segera tersedia di versi mendatang.',
    ),
    _FaqItem(
      category: 'Akun & Keamanan',
      icon: Icons.person_outline,
      color: Color(0xFF1a56db),
      question: 'Kenapa saya tidak bisa login ke akun KyPay?',
      answer:
          'Pastikan kamu memasukkan nomor HP dan password yang benar. '
          'Jika lupa password, gunakan fitur "Lupa Password" di halaman login '
          'untuk mereset password melalui email yang terdaftar.',
    ),
    _FaqItem(
      category: 'Transfer & Pembayaran',
      icon: Icons.send_outlined,
      color: Color(0xFF0891b2),
      question: 'Berapa batas maksimal transfer per hari?',
      answer:
          'Batas transfer harian KyPay adalah Rp 5.000.000 per hari. '
          'Untuk meningkatkan limit transfer, hubungi tim support kami.',
    ),
    _FaqItem(
      category: 'Transfer & Pembayaran',
      icon: Icons.send_outlined,
      color: Color(0xFF0891b2),
      question: 'Mengapa transfer saya gagal padahal saldo mencukupi?',
      answer:
          'Transfer bisa gagal karena beberapa sebab: PIN salah, nomor wallet '
          'tujuan tidak valid, koneksi internet tidak stabil, atau saldo harian '
          'sudah mencapai batas limit. Coba periksa kembali dan ulangi transaksi.',
    ),
    _FaqItem(
      category: 'Top Up',
      icon: Icons.add_card_outlined,
      color: Color(0xFF27ae60),
      question: 'Berapa lama proses top up saldo?',
      answer:
          'Top up saldo biasanya diproses dalam 1x24 jam setelah bukti transfer '
          'diterima dan diverifikasi oleh admin KyPay. Kamu akan mendapat notifikasi '
          'setelah saldo berhasil ditambahkan.',
    ),
    _FaqItem(
      category: 'Top Up',
      icon: Icons.add_card_outlined,
      color: Color(0xFF27ae60),
      question: 'Apakah ada biaya untuk melakukan top up?',
      answer:
          'Saat ini KyPay tidak mengenakan biaya tambahan untuk top up saldo. '
          'Namun perhatikan biaya transfer dari bank atau metode pembayaran '
          'yang kamu gunakan.',
    ),
    _FaqItem(
      category: 'QR Payment',
      icon: Icons.qr_code_outlined,
      color: Color(0xFF9b59b6),
      question: 'Berapa lama QR Code berlaku setelah dibuat?',
      answer:
          'QR Code KyPay berlaku selama 5 menit (300 detik) setelah dibuat. '
          'Jika QR sudah kadaluarsa sebelum dibayar, kamu perlu membuat QR baru.',
    ),
    _FaqItem(
      category: 'QR Payment',
      icon: Icons.qr_code_outlined,
      color: Color(0xFF9b59b6),
      question: 'Apakah QR untuk Bayar & Beli berbeda dengan QR Transfer?',
      answer:
          'Ya, berbeda. QR Transfer digunakan untuk menerima kiriman saldo '
          'dari pengguna KyPay lain. Sedangkan QR Bayar & Beli digunakan '
          'untuk pembayaran produk seperti pulsa, token listrik, dll.',
    ),
  ];

  // Grup FAQ berdasarkan kategori
  Map<String, List<_FaqItem>> get _grouped {
    final Map<String, List<_FaqItem>> map = {};
    for (final faq in _faqs) {
      map.putIfAbsent(faq.category, () => []).add(faq);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bantuan',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Hero banner ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1a3a6b), Color(0xFF0f1b35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                //ignore: deprecated_member_use
                  color: const Color(0xFF1a56db).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: const Color(0xFF1a56db).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Color(0xFF1a56db), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pusat Bantuan KyPay',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Temukan jawaban atas pertanyaanmu di sini.',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── FAQ label ──────────────────────────────────────────
          Text('Pertanyaan yang Sering Ditanyakan',
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),

          const SizedBox(height: 14),

          // ── FAQ accordion ──────────────────────────────────────
          ..._buildFaqList(),

          const SizedBox(height: 28),

          // ── Divider ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                //ignore: deprecated_member_use
                  child: Divider(color: Colors.white.withOpacity(0.08))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Masih butuh bantuan?',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12)),
              ),
              Expanded(
                //ignore: deprecated_member_use
                  child: Divider(color: Colors.white.withOpacity(0.08))),
            ],
          ),

          const SizedBox(height: 20),

          // ── Hubungi kami ───────────────────────────────────────
          Text('Hubungi Kami',
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),

          const SizedBox(height: 12),

          _buildContactItem(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF25D366),
            title: 'WhatsApp Support',
            subtitle: '+62 812-3456-7890',
            onTap: () => _copyToClipboard(context, '+6281234567890'),
          ),
          const SizedBox(height: 10),
          _buildContactItem(
            icon: Icons.email_outlined,
            color: const Color(0xFF1a56db),
            title: 'Email Support',
            subtitle: 'support@kypay.id',
            onTap: () => _copyToClipboard(context, 'support@kypay.id'),
          ),
          const SizedBox(height: 10),
          _buildContactItem(
            icon: Icons.access_time_outlined,
            color: const Color(0xFFd97706),
            title: 'Jam Operasional',
            subtitle: 'Senin – Jumat, 08.00 – 17.00 WIB',
            onTap: null,
          ),

          const SizedBox(height: 28),

          // ── Versi app ─────────────────────────────────────────
          Center(
            child: Text('KyPay v1.0.0',
                style: TextStyle(
                  //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2), fontSize: 11)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Build FAQ list grouped by category ──────────────────────
  List<Widget> _buildFaqList() {
    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final entry in _grouped.entries) {
      // Category header
      final firstItem = entry.value.first;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Icon(firstItem.icon, color: firstItem.color, size: 14),
            const SizedBox(width: 6),
            Text(entry.key,
                style: TextStyle(
                    color: firstItem.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ));

      for (final faq in entry.value) {
        final index = globalIndex;
        final isOpen = _openIndex == index;
        widgets.add(_buildFaqItem(faq, index, isOpen));
        globalIndex++;
      }

      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildFaqItem(_FaqItem faq, int index, bool isOpen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOpen
        //ignore: deprecated_member_use
            ? faq.color.withOpacity(0.07)
            //ignore: deprecated_member_use
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
          //ignore: deprecated_member_use
              ? faq.color.withOpacity(0.3)
              //ignore: deprecated_member_use
              : Colors.white.withOpacity(0.07),
          width: isOpen ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            setState(() => _openIndex = isOpen ? -1 : index),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: TextStyle(
                          color: isOpen
                              ? Colors.white
                              //ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen ? faq.color : Colors.white38,
                      size: 20,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.5),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contact item ─────────────────────────────────────────────
  Widget _buildContactItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          //ignore: deprecated_member_use
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(subtitle,
                      style: TextStyle(
                        //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy_outlined,
                  color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text disalin!'),
        backgroundColor: const Color(0xFF1a56db),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _FaqItem {
  final String category;
  final IconData icon;
  final Color color;
  final String question;
  final String answer;

  const _FaqItem({
    required this.category,
    required this.icon,
    required this.color,
    required this.question,
    required this.answer,
  });
}