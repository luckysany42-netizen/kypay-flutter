import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../blocs/qr/qr_bloc.dart';
import '../../blocs/qr/qr_event.dart';
import '../../blocs/qr/qr_state.dart';
import '../../services/api_service.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../widgets/struk_widget.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _pinController = TextEditingController();
  final _scanController = MobileScannerController();

  bool _scanning = false;
  bool _torchOn = false;
  double _balance = 0;

  String formatRupiah(double val) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(val);

  @override
  void initState() {
    super.initState();
    final ws = context.read<WalletBloc>().state;
    if (ws is WalletLoaded) _balance = ws.wallet.balance;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        title: const Text(
          'Scan & Bayar QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            final state = context.read<QrBloc>().state;
            // Jangan reset QR yang sedang menunggu pembayaran (dari Transfer/Bayar)
            if (state is! QrGenerated) {
              context.read<QrBloc>().add(ResetQr());
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Saldo',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
                Text(
                  formatRupiah(_balance),
                  style: const TextStyle(
                    color: Color(0xFF1a56db),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<QrBloc, QrState>(
            listener: (context, state) {
              if (state is QrPaySuccess) {
                context.read<WalletBloc>().add(FetchWallet());
              }
              if (state is QrError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _scanning = false);
              }
            },
          ),
          BlocListener<WalletBloc, WalletState>(
            listener: (context, walletState) {
              if (walletState is WalletLoaded) {
                setState(() => _balance = walletState.wallet.balance);
              }
            },
          ),
        ],
        child: BlocBuilder<QrBloc, QrState>(
          builder: (context, state) {
          // ✅ QR sedang menunggu dari Transfer/Bayar & Beli — tampilkan info
          if (state is QrGenerated) return _buildActiveQrInfo(state);

          // Setelah scan → konfirmasi bayar
          if (state is QrScanned) return _buildConfirmPay(state);

          // Bayar sukses
          if (state is QrPaySuccess) return _buildPaySuccess(state);

          // Loading
          if (state is QrLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a56db)),
            );
          }

          // Default: kamera scan
          return _buildScanner();
        },
      ),
    )
    );
  }

  // ── Info QR Aktif (dari Transfer/Bayar) ─────────────────────────────────
  Widget _buildActiveQrInfo(QrGenerated state) {
    final isExpiringSoon = state.secondsLeft <= 60;
    final minutes = state.secondsLeft ~/ 60;
    final seconds = state.secondsLeft % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Info QR sedang aktif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: const Color(0xFF1a56db).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                //ignore: deprecated_member_use
                color: const Color(0xFF1a56db).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1a56db),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR Sedang Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Ada QR yang menunggu pembayaran. '
                        'Minta orang lain untuk scan QR tersebut.',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Countdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpiringSoon
              //ignore: deprecated_member_use
                  ? Colors.red.withOpacity(0.1)
                  //ignore: deprecated_member_use
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpiringSoon
                //ignore: deprecated_member_use
                    ? Colors.red.withOpacity(0.3)
                    //ignore: deprecated_member_use
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timer,
                  color: isExpiringSoon ? Colors.red : Colors.white54,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isExpiringSoon ? Colors.red : Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'QR berlaku selama waktu ini',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Jumlah
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                Text(
                  formatRupiah(state.amount),
                  style: const TextStyle(
                    color: Color(0xFF1a56db),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Loading indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Color(0xFF1a56db),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Menunggu pembayaran...',
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Instruksi untuk pembayar — bisa juga scan QR lain
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atau scan QR orang lain:',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Jangan batalkan QR yang aktif, hanya scan QR lain
                      // Navigasi ke scanner manual tanpa reset QrBloc
                      _showManualTokenDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      //ignore: deprecated_member_use
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white70,
                      size: 18,
                    ),
                    label: Text(
                      'Masukkan Token QR Manual',
                      //ignore: deprecated_member_use
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualTokenDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1e2d50),
        title: const Text(
          'Masukkan Token QR',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Token QR dari penerima...',
            //ignore: deprecated_member_use
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            //ignore: deprecated_member_use
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              //ignore: deprecated_member_use
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                context.read<QrBloc>().add(ScanQrToken(controller.text.trim()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a56db),
            ),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  // ── Kamera Scanner ───────────────────────────────────────────────────────
  Widget _buildScanner() {
    return Column(
      children: [
        // Info saldo
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: const Color(0xFF1a56db).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            //ignore: deprecated_member_use
            border: Border.all(color: const Color(0xFF1a56db).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF1a56db),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Saldo tersedia: ${formatRupiah(_balance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              // Kamera
              MobileScanner(
                controller: _scanController,
                onDetect: (capture) {
                  if (_scanning) return;
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    setState(() => _scanning = true);
                    context.read<QrBloc>().add(ScanQrToken(barcode!.rawValue!));
                  }
                },
              ),

              // Overlay
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1a56db),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      ...[
                        Alignment.topLeft,
                        Alignment.topRight,
                        Alignment.bottomLeft,
                        Alignment.bottomRight,
                      ].map(
                        (align) => Align(
                          alignment: align,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                top: align.y < 0
                                    ? const BorderSide(
                                        color: Color(0xFF1a56db),
                                        width: 4,
                                      )
                                    : BorderSide.none,
                                bottom: align.y > 0
                                    ? const BorderSide(
                                        color: Color(0xFF1a56db),
                                        width: 4,
                                      )
                                    : BorderSide.none,
                                left: align.x < 0
                                    ? const BorderSide(
                                        color: Color(0xFF1a56db),
                                        width: 4,
                                      )
                                    : BorderSide.none,
                                right: align.x > 0
                                    ? const BorderSide(
                                        color: Color(0xFF1a56db),
                                        width: 4,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Instruksi + torch
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Arahkan kamera ke QR Code KyPay',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        _scanController.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _torchOn
                              ? const Color(0xFF1a56db)
                              : Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _torchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Input manual
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0f1b35),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Atau masukkan token QR manual...',
                    //ignore: deprecated_member_use
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    //ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      context.read<QrBloc>().add(ScanQrToken(val.trim()));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Konfirmasi Bayar ─────────────────────────────────────────────────────
  Widget _buildConfirmPay(QrScanned state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1a56db),
                  radius: 28,
                  child: Text(
                    state.merchantName.isNotEmpty
                        ? state.merchantName[0].toUpperCase()
                        : 'K',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.merchantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.description != null)
                  Text(
                    state.description!,
                    style: TextStyle(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                if (state.isBillPayment)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      //ignore: deprecated_member_use
                      color: const Color(0xFFd97706).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Bayar & Beli',
                      style: TextStyle(
                        color: Color(0xFFd97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const Divider(color: Colors.white12, height: 28),

                _buildRow(
                  'Jumlah',
                  formatRupiah(state.amount),
                  valueColor: const Color(0xFF1a56db),
                ),
                const SizedBox(height: 8),
                _buildRow('Biaya Admin', 'Gratis', valueColor: Colors.green),
                const Divider(color: Colors.white12),
                _buildRow(
                  'Total Bayar',
                  formatRupiah(state.amount),
                  valueColor: Colors.red,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  'Saldo Setelah',
                  formatRupiah(_balance - state.amount),
                  valueColor: Colors.white70,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Masukkan PIN KyPay',
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 8,
              ),
              counterText: '',
              filled: true,
              //ignore: deprecated_member_use
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1a56db),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<QrBloc>().add(ResetQr());
                    setState(() => _scanning = false);
                  },
                  style: OutlinedButton.styleFrom(
                    //ignore: deprecated_member_use
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Batal',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BlocBuilder<QrBloc, QrState>(
                  builder: (context, s) {
                    return ElevatedButton(
                      onPressed: s is QrLoading
                          ? null
                          : () {
                              if (_pinController.text.length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PIN harus 6 digit'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              context.read<QrBloc>().add(
                                PayQr(
                                  token: state.token,
                                  pin: _pinController.text,
                                ),
                              );
                              _pinController.clear();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a56db),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: s is QrLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Bayar Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bayar Sukses ─────────────────────────────────────────────────────────
  Widget _buildPaySuccess(QrPaySuccess state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ke ${state.merchantName}',
              style: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatRupiah(state.amount),
              style: const TextStyle(
                color: Color(0xFF1a56db),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),

            if (state.isBillPayment && state.resultCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: const Color(0xFFd97706).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    //ignore: deprecated_member_use
                    color: const Color(0xFFd97706).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kode Produk',
                      style: TextStyle(
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.resultCode!,
                      style: const TextStyle(
                        color: Color(0xFFd97706),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Ref: ${state.transactionNumber}',
              style: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  showStrukModal(
                    context,
                    StrukWidget(
                      type: 'payment',
                      amount: state.amount,
                      referenceNumber: state.transactionNumber,
                      productName: state.isBillPayment
                          ? 'Pembayaran QR'
                          : state.merchantName,
                      provider: state.merchantName,
                      paymentMethod: 'QR KyPay',
                      resultCode: state.isBillPayment ? state.resultCode : null,
                      resultCodeLabel: state.isBillPayment
                          ? 'Kode Produk'
                          : null,
                      tanggal: DateTime.now(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  //ignore: deprecated_member_use
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.receipt_long,
                  color: Colors.white70,
                  size: 18,
                ),
                label: const Text(
                  'Lihat Struk',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.read<QrBloc>().add(ResetQr());
                  setState(() => _scanning = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Scan QR Lagi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          //ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
