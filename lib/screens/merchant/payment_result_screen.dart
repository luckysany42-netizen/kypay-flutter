import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../widgets/struk_widget.dart';

/// Layar hasil pembayaran merchant — pakai StrukWidget yang sudah ada
class PaymentResultScreen extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  final bool                 isSuccess;

  const PaymentResultScreen({
    super.key,
    required this.receiptData,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Status Icon ────────────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, val, child) => Transform.scale(scale: val, child: child),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      //ignore: deprecated_member_use
                      color: isSuccess ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 52,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                isSuccess ? 'Pembayaran Berhasil!' : 'Pembayaran Gagal',
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontSize: 26, fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess
                    ? 'Transaksi kamu telah berhasil diproses.'
                    : 'Saldo kamu tidak dipotong. Coba lagi.',
                textAlign: TextAlign.center,
                //ignore: deprecated_member_use
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
              ),

              const Spacer(),

              // ── Tombol Lihat Struk (pakai StrukWidget yang sudah ada) ───
              if (isSuccess) ...[
                SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showStrukModal(
                        context,
                        StrukWidget(
                          type:            'payment',
                          amount:          (receiptData['total_amount'] as num?)?.toDouble() ?? 0,
                          referenceNumber: receiptData['provider_reference']?.toString()
                              ?? receiptData['transaction_id']?.toString()
                              ?? '-',
                          productName:     receiptData['product_name']?.toString() ?? '-',
                          provider:        receiptData['merchant_name']?.toString() ?? '-',
                          targetNumber:    receiptData['input_value']?.toString() ?? '-',
                          targetLabel:     'Tujuan',
                          paymentMethod:   'Saldo KyPay',
                          // Token/SN untuk PLN, Game voucher, dll
                          resultCode:      receiptData['receipt_data']?['sn']?.toString(),
                          resultCodeLabel: _getResultCodeLabel(receiptData['merchant_code']?.toString()),
                          tanggal:         DateTime.now(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                    label: const Text('Lihat Struk',
                      style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      //ignore: deprecated_member_use
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Kembali ke Beranda ─────────────────────────────────────
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Refresh data sebelum kembali supaya merchant grid tidak hilang
                    context.read<MerchantBloc>().add(LoadFeatured());
                    context.read<WalletBloc>().add(FetchWallet());
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a56db),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Beranda',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getResultCodeLabel(String? merchantCode) {
    if (merchantCode == null) return null;
    if (merchantCode.contains('PLN')) return 'Token Listrik';
    if (['ML', 'FF', 'PUBG'].contains(merchantCode)) return 'Voucher Code';
    return null;
  }
}