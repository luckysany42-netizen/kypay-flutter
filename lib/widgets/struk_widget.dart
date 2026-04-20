import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget struk digital yang bisa dipakai di Transfer maupun Bayar & Beli.
/// Tampilannya menyerupai struk web KyPay (kertas putih, font monospace style).
class StrukWidget extends StatelessWidget {
  final String type; // 'transfer' atau 'payment'

  // Transfer fields
  final String? receiverName;
  final String? receiverWallet;
  final String? note;

  // Payment fields
  final String? productName;
  final String? provider;
  final String? targetNumber;
  final String? targetLabel;
  final String? paymentMethod; // 'Saldo KyPay' / 'QR KyPay'
  final String? resultCode;
  final String? resultCodeLabel;

  // Common
  final double amount;
  final String referenceNumber;
  final DateTime? tanggal;

  const StrukWidget({
    super.key,
    required this.type,
    required this.amount,
    required this.referenceNumber,
    this.receiverName,
    this.receiverWallet,
    this.note,
    this.productName,
    this.provider,
    this.targetNumber,
    this.targetLabel,
    this.paymentMethod,
    this.resultCode,
    this.resultCodeLabel,
    this.tanggal,
  });

  static const List<String> _bulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get _formattedDate {
    final d = tanggal ?? DateTime.now();
    final day = d.day.toString().padLeft(2, '0');
    final month = _bulan[d.month];
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    return '$day $month $year pukul $hour.$minute.$second';
  }

  String formatRupiah(double val) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(val);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────
          const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFFf59e0b),
            size: 40,
          ),
          const SizedBox(height: 6),
          const Text(
            'KyPay',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1e293b),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            type == 'transfer'
                ? 'Struk Transfer Digital'
                : 'Struk Pembayaran Digital',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748b)),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedDate,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94a3b8)),
          ),

          _divider(),

          // ── Status ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16a34a),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                type == 'transfer'
                    ? 'TRANSFER BERHASIL'
                    : 'PEMBAYARAN BERHASIL',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF16a34a),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          _divider(),

          // ── Detail Rows ──────────────────────────────────
          if (type == 'transfer') ...[
            _row('Penerima', receiverName ?? '-'),
            const SizedBox(height: 6),
            _row('No. Wallet', receiverWallet ?? '-'),
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _row('Catatan', note!),
            ],
            const SizedBox(height: 6),
            _row('Biaya Admin', 'Gratis', valueColor: const Color(0xFF16a34a)),
          ] else ...[
            _row('Produk', productName ?? '-'),
            if (provider != null && provider!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _row('Provider', provider!),
            ],
            const SizedBox(height: 6),
            _row(targetLabel ?? 'Tujuan', targetNumber ?? '-'),
            const SizedBox(height: 6),
            _row('Metode Bayar', paymentMethod ?? 'Saldo KyPay'),
            const SizedBox(height: 6),
            _row('Biaya Admin', 'Gratis', valueColor: const Color(0xFF16a34a)),
          ],

          _divider(),

          // ── Total ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type == 'transfer' ? 'Total Transfer' : 'Total Dibayar',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
              Text(
                formatRupiah(amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),

          // ── Kode hasil (token listrik / voucher game) ────
          if (resultCode != null && resultCode!.isNotEmpty) ...[
            _divider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFfefce8),
                border: Border.all(
                  color: const Color(0xFFfbbf24),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    resultCodeLabel ?? 'Kode Hasil',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF92400e),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resultCode!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFb45309),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simpan kode ini dengan baik',
                    style: TextStyle(fontSize: 9, color: Color(0xFFa16207)),
                  ),
                ],
              ),
            ),
          ],

          _divider(),

          // ── Referensi ─────────────────────────────────────
          Column(
            children: [
              const Text(
                'No. Referensi',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748b)),
              ),
              const SizedBox(height: 4),
              Text(
                referenceNumber,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          _divider(),

          // ── Footer ───────────────────────────────────────
          const Text(
            'Terima kasih telah menggunakan KyPay',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748b)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Struk ini merupakan bukti transaksi yang sah',
            style: TextStyle(fontSize: 9, color: Color(0xFF9ca3af)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [Expanded(child: DashedLine())]),
  );

  Widget _row(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1e293b),
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

/// Garis putus-putus horizontal
class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1.5,
              margin: const EdgeInsets.only(right: dashSpace),
              color: const Color(0xFFe2e8f0),
            ),
          ),
        );
      },
    );
  }
}

/// Modal struk yang bisa dipanggil dari mana saja.
/// Gunakan [showStrukModal] untuk menampilkannya.
Future<void> showStrukModal(BuildContext context, StrukWidget struk) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StrukModal(struk: struk),
  );
}

class _StrukModal extends StatelessWidget {
  final StrukWidget struk;
  const _StrukModal({required this.struk});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFf8fafc),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    struk.type == 'transfer'
                        ? 'Struk Transfer'
                        : 'Struk Pembayaran',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ),

            // Struk content
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        //ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: struk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
