import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kypay/models/merchant_model.dart';
import 'package:kypay/models/merchant_product_model.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../../blocs/qr/qr_bloc.dart';
import '../../blocs/qr/qr_event.dart';
import '../../blocs/qr/qr_state.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import 'payment_result_screen.dart';

/// Layar konfirmasi + pilih metode pembayaran (saldo atau QR)
class PaymentConfirmScreen extends StatefulWidget {
  final MerchantModel        merchant;
  final MerchantProductModel product;
  final String               inputValue;

  const PaymentConfirmScreen({
    super.key,
    required this.merchant,
    required this.product,
    required this.inputValue,
  });

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  final _pinController = TextEditingController();
  String _pin          = '';
  bool   _obscurePin   = true;

  // 'saldo' atau 'qr'
  String _paymentMethod = 'saldo';

  // Step dalam layar ini: 1=pilih metode, 2=konfirmasi (PIN atau QR)
  int _step = 1;

  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  double get _currentBalance {
    final ws = context.read<WalletBloc>().state;
    return ws is WalletLoaded ? ws.wallet.balance : 0;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onLanjut() {
    if (_paymentMethod == 'saldo') {
      setState(() => _step = 2);
    } else {
      // Generate QR untuk pembayaran merchant
      context.read<QrBloc>().add(GenerateQrBill(
        productCode:  widget.product.code,
        targetNumber: widget.inputValue,
        amount:       widget.product.totalPrice,
      ));
      setState(() => _step = 2);
    }
  }

  void _submitSaldo() {
    if (_pin.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Masukkan PIN 6 digit'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    context.read<MerchantBloc>().add(SubmitPayment(
      merchantId: widget.merchant.id,
      productId:  widget.product.id,
      inputValue: widget.inputValue,
      pin:        _pin,
    ));
  }

  // ── Handler QrPaymentReceived (device generate QR) ──────────────────────────
  void _handleQrPaymentReceived(QrPaymentReceived state) {
    context.read<MerchantBloc>().add(LoadFeatured());
    context.read<WalletBloc>().add(FetchWallet());

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MerchantBloc>()),
          BlocProvider.value(value: context.read<WalletBloc>()),
        ],
        child: PaymentResultScreen(
          receiptData: {
            'merchant_name':      widget.merchant.name,
            'product_name':       widget.product.name,
            'input_value':        widget.inputValue,
            'total_amount':       state.amount,
            'admin_fee':          widget.product.adminFee,
            'provider_reference': state.transactionNumber,
            'status_label':       'Berhasil',
            'created_at':         DateTime.now().toIso8601String(),
          },
          isSuccess: true,
        ),
      ),
    ));
  }

  // ── Handler QrPaySuccess (device scan QR) ──────────────────────────────────
  void _handleQrPaySuccess(QrPaySuccess state) {
    context.read<MerchantBloc>().add(LoadFeatured());
    context.read<WalletBloc>().add(FetchWallet());

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MerchantBloc>()),
          BlocProvider.value(value: context.read<WalletBloc>()),
        ],
        child: PaymentResultScreen(
          receiptData: {
            'merchant_name': widget.merchant.name,
            'product_name':  widget.product.name,
            'input_value':   widget.inputValue,
            'total_amount':  state.amount,
            'admin_fee':     widget.product.adminFee,
          },
          isSuccess: true,
        ),
      ),
    ));
  }

  String _formatTime(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_step == 2) {
              // Batalkan QR jika aktif
              final qrState = context.read<QrBloc>().state;
              if (qrState is QrGenerated) {
                context.read<QrBloc>().add(CancelQr(qrState.token));
              }
              _pinController.clear();
              setState(() { _step = 1; _pin = ''; });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1 ? 'Metode Pembayaran' : 'Konfirmasi Pembayaran',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MerchantBloc, MerchantState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<MerchantBloc>()),
                      BlocProvider.value(value: context.read<WalletBloc>()),
                    ],
                    child: PaymentResultScreen(
                      receiptData: state.receiptData,
                      isSuccess:   true,
                    ),
                  ),
                ));
              } else if (state is MerchantError) {
                _pinController.clear();
                setState(() => _pin = '');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ));
              }
            },
          ),
          BlocListener<QrBloc, QrState>(
            listener: (context, state) {
              // QrPaymentReceived = device yang GENERATE QR (penerima pembayaran)
              // QrPaySuccess      = device yang SCAN QR (pembayar)
              if (state is QrPaymentReceived) {
                // Device generate QR: fetch receipt dari backend dulu
                _handleQrPaymentReceived(state);
              } else if (state is QrPaySuccess) {
                // Device scan QR: langsung tampilkan dengan data dari QrPaySuccess
                _handleQrPaySuccess(state);
              }
            },
          ),
        ],
        child: _step == 1 ? _buildStep1Method() : _buildStep2Confirm(),
      ),
    );
  }

  // ── Step 1: Pilih Metode ───────────────────────────────────────────────────
  Widget _buildStep1Method() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Ringkasan order ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      //ignore: deprecated_member_use
                      color: const Color(0xFF1a56db).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(_emoji(widget.merchant.category?.code),
                      style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.merchant.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(widget.product.name,
                        //ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  )),
                  Text(_fmt.format(widget.product.totalPrice),
                    style: const TextStyle(color: Color(0xFF1a56db), fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 14),
                _divider(),
                const SizedBox(height: 14),
                _row(widget.merchant.inputConfig.label, widget.inputValue),
                const SizedBox(height: 8),
                _row('Harga',        _fmt.format(widget.product.sellingPrice)),
                const SizedBox(height: 8),
                _row('Biaya Admin',  _fmt.format(widget.product.adminFee)),
                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),
                _row('Total Bayar', _fmt.format(widget.product.totalPrice),
                  valueColor: const Color(0xFF1a56db), bold: true),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text('Pilih Metode Pembayaran',
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),

          // ── Opsi Saldo KyPay ─────────────────────────────────────────────
          _methodCard(
            selected:  _paymentMethod == 'saldo',
            color:     const Color(0xFFd97706),
            icon:      Icons.account_balance_wallet,
            title:     'Saldo KyPay',
            subtitle:  'Saldo: ${_fmt.format(_currentBalance)}',
            onTap:     () => setState(() => _paymentMethod = 'saldo'),
          ),

          const SizedBox(height: 12),

          // ── Opsi QR ──────────────────────────────────────────────────────
          _methodCard(
            selected:  _paymentMethod == 'qr',
            color:     const Color(0xFF1a56db),
            icon:      Icons.qr_code,
            title:     'QR Code',
            subtitle:  'Bayar lewat QR — minta orang lain scan',
            onTap:     () => setState(() => _paymentMethod = 'qr'),
          ),

          const SizedBox(height: 32),

          // ── Tombol Lanjut ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _onLanjut,
              style: ElevatedButton.styleFrom(
                backgroundColor: _paymentMethod == 'saldo'
                    ? const Color(0xFFd97706)
                    : const Color(0xFF1a56db),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _paymentMethod == 'saldo'
                    ? 'Lanjut — Masukkan PIN'
                    : 'Buat QR Pembayaran',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline,
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3), size: 14),
              const SizedBox(width: 6),
              Text('Transaksi diproteksi PIN KyPay',
                //ignore: deprecated_member_use
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Konfirmasi (PIN atau QR) ──────────────────────────────────────
  Widget _buildStep2Confirm() {
    if (_paymentMethod == 'qr') {
      return _buildQrDisplay();
    }
    return _buildPinInput();
  }

  // ── PIN Input ──────────────────────────────────────────────────────────────
  Widget _buildPinInput() {
    return BlocBuilder<MerchantBloc, MerchantState>(
      builder: (context, state) {
        final isLoading = state is MerchantLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // Ringkasan ringkas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                //ignore: deprecated_member_use
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(children: [
                _row(widget.merchant.inputConfig.label, widget.inputValue),
                const SizedBox(height: 8),
                _row('Produk', widget.product.name),
                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),
                _row('Total Bayar', _fmt.format(widget.product.totalPrice),
                  valueColor: const Color(0xFF1a56db), bold: true),
                const SizedBox(height: 8),
                _row('Saldo Setelah',
                  _fmt.format(_currentBalance - widget.product.totalPrice),
                  //ignore: deprecated_member_use
                  valueColor: Colors.white.withOpacity(0.6)),
              ]),
            ),

            const SizedBox(height: 28),

            Text('Masukkan PIN KyPay',
              style: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.7),
                fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _pinController,
              enabled: !isLoading,
              obscureText: _obscurePin,
              obscuringCharacter: '●',
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 52,
                fieldWidth: 46,
                //ignore: deprecated_member_use
                activeFillColor: const Color(0xFFd97706).withOpacity(0.15),
                //ignore: deprecated_member_use
                inactiveFillColor: Colors.white.withOpacity(0.05),
                //ignore: deprecated_member_use
                selectedFillColor: const Color(0xFFd97706).withOpacity(0.1),
                activeColor:    const Color(0xFFd97706),
                //ignore: deprecated_member_use
                inactiveColor:  Colors.white.withOpacity(0.15),
                selectedColor:  const Color(0xFFd97706),
              ),
              enableActiveFill: true,
              textStyle: const TextStyle(color: Colors.white, fontSize: 18),
              onChanged: (val) => setState(() => _pin = val),
              onCompleted: (_) => _submitSaldo(),
            ),

            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GestureDetector(
                onTap: () => setState(() => _obscurePin = !_obscurePin),
                child: Text(
                  _obscurePin ? 'Tampilkan PIN' : 'Sembunyikan PIN',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ),
            ]),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (isLoading || _pin.length < 6) ? null : _submitSaldo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd97706),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Bayar ${_fmt.format(widget.product.totalPrice)}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── QR Display ────────────────────────────────────────────────────────────
  Widget _buildQrDisplay() {
    return BlocBuilder<QrBloc, QrState>(
      builder: (context, state) {
        if (state is QrLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1a56db)));
        }

        if (state is QrError) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(state.message,
                style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1a56db)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ));
        }

        if (state is QrGenerated) {
          final isExpiringSoon = state.secondsLeft <= 60;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [

              // QR Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    //ignore: deprecated_member_use
                    BoxShadow(color: const Color(0xFF1a56db).withOpacity(0.3),
                      blurRadius: 30, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a56db),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 6),
                    const Text('KyPay Bayar & Beli',
                      style: TextStyle(
                        color: Color(0xFF1a56db), fontSize: 13, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: state.token,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1a56db)),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0f1b35)),
                  ),
                  const SizedBox(height: 12),
                  Text(_fmt.format(state.amount),
                    style: const TextStyle(
                      color: Color(0xFF1a56db), fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('${widget.merchant.name} — ${widget.product.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      //ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.5), fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 16),

              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: isExpiringSoon ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    //ignore: deprecated_member_use
                    color: isExpiringSoon ? Colors.red.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.timer,
                    color: isExpiringSoon ? Colors.red : Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Text('Berlaku: ${_formatTime(state.secondsLeft)}',
                    style: TextStyle(
                      color: isExpiringSoon ? Colors.red : Colors.white70,
                      fontWeight: FontWeight.w600)),
                ]),
              ),

              const SizedBox(height: 12),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(color: Color(0xFF1a56db), strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Menunggu pembayaran...',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ]),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'QR ini aktif saat pindah menu. Minta pembayar scan di QR → Scan & Bayar.',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.amber.withOpacity(0.9), fontSize: 12))),
                ]),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  context.read<QrBloc>().add(CancelQr(state.token));
                  setState(() => _step = 1);
                },
                child: const Text('Batalkan & Ganti Metode',
                  style: TextStyle(color: Colors.red)),
              ),
            ]),
          );
        }

        return const Center(child: CircularProgressIndicator(color: Color(0xFF1a56db)));
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _methodCard({
    required bool     selected,
    required Color    color,
    required IconData icon,
    required String   title,
    required String   subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: selected ? color.withOpacity(0.12) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            //ignore: deprecated_member_use
            color: selected ? color : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(subtitle,
                //ignore: deprecated_member_use
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          )),
          if (selected) Icon(Icons.check_circle, color: color),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          //ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Flexible(child: Text(value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor ?? Colors.white.withOpacity(0.9),//ignore: deprecated_member_use
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ))),
      ],
    );
  }

  Widget _divider() => Container(height: 1,
    //ignore: deprecated_member_use
    color: Colors.white.withOpacity(0.07));

  String _emoji(String? code) => switch (code ?? '') {
    'game'    => '🎮',
    'pulsa'   => '📱',
    'tagihan' => '📄',
    'rumah'   => '⚡',
    'hiburan' => '🎵',
    _         => '💳',
  };
}