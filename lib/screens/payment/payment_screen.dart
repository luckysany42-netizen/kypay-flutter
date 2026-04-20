import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_event.dart';
import '../../blocs/payment/payment_state.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../blocs/qr/qr_bloc.dart';
import '../../blocs/qr/qr_event.dart';
import '../../blocs/qr/qr_state.dart';
// ignore: unused_import
import '../../widgets/struk_widget.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _targetController = TextEditingController();
  final _pinController = TextEditingController();

  // step: 1=kategori, 2=produk, 3=pilih metode, 4=konfirmasi PIN (saldo), 5=sukses
  int _step = 1;
  String _selectedCategory = '';
  double _currentBalance = 0;
  // 'saldo' atau 'qr'
  String _paymentMethod = 'saldo';

  final List<Map<String, dynamic>> _categories = [
    {
      'key': 'pulsa',
      'label': 'Pulsa',
      'icon': Icons.phone_android,
      'color': const Color(0xFFe74c3c),
    },
    {
      'key': 'paket_data',
      'label': 'Paket Data',
      'icon': Icons.wifi,
      'color': const Color(0xFF3498db),
    },
    {
      'key': 'token_listrik',
      'label': 'Token Listrik',
      'icon': Icons.bolt,
      'color': const Color(0xFFf1c40f),
    },
    {
      'key': 'bpjs',
      'label': 'BPJS',
      'icon': Icons.favorite,
      'color': const Color(0xFF27ae60),
    },
    {
      'key': 'voucher_game',
      'label': 'Voucher Game',
      'icon': Icons.sports_esports,
      'color': const Color(0xFF9b59b6),
    },
  ];

  String get _targetLabel {
    switch (_selectedCategory) {
      case 'pulsa':
      case 'paket_data':
        return 'Nomor HP Tujuan';
      case 'token_listrik':
        return 'Nomor Meter / ID PLN';
      case 'bpjs':
        return 'Nomor Peserta BPJS';
      case 'voucher_game':
        return 'ID Game';
      default:
        return 'Nomor Tujuan';
    }
  }

  String get _targetHint {
    switch (_selectedCategory) {
      case 'pulsa':
      case 'paket_data':
        return '08123456789';
      case 'token_listrik':
        return 'Contoh: 12345678901';
      case 'bpjs':
        return '13 digit angka';
      case 'voucher_game':
        return 'ID Game kamu';
      default:
        return '';
    }
  }

  String formatRupiah(double val) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(val);

  String formatTime(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  double _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final ws = context.read<WalletBloc>().state;
    if (ws is WalletLoaded) _currentBalance = ws.wallet.balance;
  }

  @override
  void dispose() {
    _targetController.dispose();
    _pinController.dispose();
    super.dispose();
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
          onPressed: () {
            if (_step > 1) {
              setState(() {
                if (_step == 2) {
                  _step = 1;
                  _targetController.clear();
                  context.read<PaymentBloc>().add(ResetPayment());
                } else if (_step == 3) {
                  _step = 2;
                } else if (_step == 4) {
                  _step = 3;
                  _pinController.clear();
                  // Jangan batalkan QR otomatis saat keluar ke menu lain;
                  // biarkan token tetap aktif sampai dipakai atau kadaluarsa.
                } else {
                  _step--;
                }
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1
              ? 'Bayar & Beli'
              : _step == 2
              ? 'Pilih Produk'
              : _step == 3
              ? 'Metode Pembayaran'
              : _step == 4
              ? 'Konfirmasi'
              : 'Pembayaran Berhasil',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_step < 5)
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
                    formatRupiah(_currentBalance),
                    style: const TextStyle(
                      color: Color(0xFFd97706),
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
          BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                context.read<WalletBloc>().add(FetchWallet());
                // Reset QR jika ada
                context.read<QrBloc>().add(ResetQr());
                setState(() => _step = 5);
              } else if (state is PaymentError) {
                _pinController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<QrBloc, QrState>(
            listener: (context, state) {
              // QR payment diterima dari scanner — langsung sukses
              if (state is QrPaySuccess) {
                context.read<WalletBloc>().add(FetchWallet());
                setState(() => _step = 5);
              }
            },
          ),
        ],
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 1:
        return _buildStep1Categories();
      case 2:
        return _buildStep2Products();
      case 3:
        return _buildStep3ChooseMethod();
      case 4:
        return _buildStep4Confirm();
      case 5:
        return _buildStep5Success();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Pilih Kategori ───────────────────────────────────────────────
  Widget _buildStep1Categories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Kategori',
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            physics: const NeverScrollableScrollPhysics(),
            children: _categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat['key'];
                    _targetController.clear();
                    _step = 2;
                  });
                  context.read<PaymentBloc>().add(FetchProducts(cat['key']));
                },
                child: Container(
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: (cat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      //ignore: deprecated_member_use
                      color: (cat['color'] as Color).withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          //ignore: deprecated_member_use
                          color: (cat['color'] as Color).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: cat['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Pilih Produk ─────────────────────────────────────────────────
  Widget _buildStep2Products() {
    final cat = _categories.firstWhere((c) => c['key'] == _selectedCategory);
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _targetLabel,
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _targetHint,
                  //ignore: deprecated_member_use
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(
                    cat['icon'] as IconData,
                    color: cat['color'] as Color,
                    size: 20,
                  ),
                  filled: true,
                  //ignore: deprecated_member_use
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cat['color'] as Color,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Pilih Nominal',
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              if (state is PaymentProductsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFd97706)),
                  ),
                ),

              if (state is PaymentProductsError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

              if (state is PaymentProductsLoaded)
                state.products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'Belum ada produk tersedia',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        children: state.products.map((product) {
                          final isSelected =
                              state.selectedProduct?['code'] == product['code'];
                          return GestureDetector(
                            onTap: () {
                              if (_targetController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Isi $_targetLabel dulu'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              context.read<PaymentBloc>().add(
                                SelectProduct(product),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                //ignore: deprecated_member_use
                                    ? (cat['color'] as Color).withOpacity(0.2)
                                    //ignore: deprecated_member_use
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (cat['color'] as Color)
                                      //ignore: deprecated_member_use
                                      : Colors.white.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product['name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: cat['color'] as Color,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                  Text(
                                    product['provider'] ?? '',
                                    style: TextStyle(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(_parsePrice(product['price'])),
                                    style: TextStyle(
                                      color: cat['color'] as Color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

              if (state is PaymentProductsLoaded &&
                  state.selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _step = 3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd97706),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Pilih Metode Pembayaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 3: Pilih Metode Pembayaran ─────────────────────────────────────
  Widget _buildStep3ChooseMethod() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, payState) {
        final product = payState is PaymentProductsLoaded
            ? payState.selectedProduct
            : null;
        final price = _parsePrice(product?['price']);
        final cat = _categories.firstWhere(
          (c) => c['key'] == _selectedCategory,
          orElse: () => _categories[0],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan produk
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: (cat['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'untuk ${_targetController.text}',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(price),
                      style: TextStyle(
                        color: cat['color'] as Color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // ── Opsi 1: Saldo KyPay ────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = 'saldo'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _paymentMethod == 'saldo'
                    //ignore: deprecated_member_use
                        ? const Color(0xFFd97706).withOpacity(0.15)
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _paymentMethod == 'saldo'
                          ? const Color(0xFFd97706)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.1),
                      width: _paymentMethod == 'saldo' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          //ignore: deprecated_member_use
                          color: const Color(0xFFd97706).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFFd97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saldo KyPay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Saldo: ${formatRupiah(_currentBalance)}',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_paymentMethod == 'saldo')
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFd97706),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Opsi 2: QR Code ────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = 'qr'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _paymentMethod == 'qr'
                    //ignore: deprecated_member_use
                        ? const Color(0xFF1a56db).withOpacity(0.15)
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _paymentMethod == 'qr'
                          ? const Color(0xFF1a56db)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.1),
                      width: _paymentMethod == 'qr' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          //ignore: deprecated_member_use
                          color: const Color(0xFF1a56db).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code,
                          color: Color(0xFF1a56db),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QR Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Bayar menggunakan QR — minta orang lain scan',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_paymentMethod == 'qr')
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1a56db),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_paymentMethod == 'saldo') {
                      _pinController.clear();
                      setState(() => _step = 4);
                      return;
                    }

                    final payState = context.read<PaymentBloc>().state;
                    final selectedProduct = payState is PaymentProductsLoaded
                        ? payState.selectedProduct
                        : null;

                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pilih produk terlebih dahulu'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final targetNumber = _targetController.text.trim();
                    if (targetNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nomor tujuan tidak boleh kosong'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Generate QR untuk pembayaran
                    context.read<QrBloc>().add(
                      GenerateQrBill(
                        productCode: selectedProduct['code'] ?? '',
                        targetNumber: targetNumber,
                        amount: price,
                      ),
                    );
                    setState(() => _step = 4);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMethod == 'saldo'
                        ? const Color(0xFFd97706)
                        : const Color(0xFF1a56db),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _paymentMethod == 'saldo'
                        ? 'Lanjut ke Konfirmasi'
                        : 'Buat QR Pembayaran',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 4: Konfirmasi (Saldo → PIN) atau QR Display ────────────────────
  Widget _buildStep4Confirm() {
    if (_paymentMethod == 'qr') {
      return _buildQrPaymentDisplay();
    }
    return _buildSaldoConfirm();
  }

  Widget _buildSaldoConfirm() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final product = state is PaymentProductsLoaded
            ? state.selectedProduct
            : null;
        final cat = _categories.firstWhere(
          (c) => c['key'] == _selectedCategory,
          orElse: () => _categories[0],
        );
        final price = _parsePrice(product?['price']);
        final isSubmitting = state is PaymentSubmitting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: (cat['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product?['name'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product?['provider'] ?? '',
                      style: TextStyle(
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),

                    const Divider(color: Colors.white12, height: 28),

                    _buildRow(_targetLabel, _targetController.text),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Metode Bayar',
                      'Saldo KyPay',
                      valueColor: const Color(0xFFd97706),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Harga',
                      formatRupiah(price),
                      valueColor: const Color(0xFFd97706),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Biaya Admin',
                      'Gratis',
                      valueColor: Colors.green,
                    ),
                    const Divider(color: Colors.white12),
                    _buildRow(
                      'Total Bayar',
                      formatRupiah(price),
                      valueColor: Colors.red,
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      'Saldo Setelah',
                      formatRupiah(_currentBalance - price),
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
                enabled: !isSubmitting,
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
                      color: Color(0xFFd97706),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd97706),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrPaymentDisplay() {
    return BlocBuilder<QrBloc, QrState>(
      builder: (context, state) {
        if (state is QrLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1a56db)),
          );
        }

        if (state is QrError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() => _step = 3),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a56db),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is QrGenerated) {
          final isExpiringSoon = state.secondsLeft <= 60;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        //ignore: deprecated_member_use
                        color: const Color(0xFF1a56db).withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a56db),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'KyPay Bayar & Beli',
                            style: TextStyle(
                              color: Color(0xFF1a56db),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: state.token,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1a56db),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0f1b35),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formatRupiah(state.amount),
                        style: const TextStyle(
                          color: Color(0xFF1a56db),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kode QR',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.token,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: state.token),
                                );
                                if (mounted) {
                                  //ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode QR disalin'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.description != null)
                        Text(
                          state.description!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isExpiringSoon
                    //ignore: deprecated_member_use
                        ? Colors.red.withOpacity(0.1)
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpiringSoon
                      //ignore: deprecated_member_use
                          ? Colors.red.withOpacity(0.4)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: isExpiringSoon ? Colors.red : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Berlaku: ${formatTime(state.secondsLeft)}',
                        style: TextStyle(
                          color: isExpiringSoon ? Colors.red : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
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

                const SizedBox(height: 16),

                // Info persisten
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    //ignore: deprecated_member_use
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'QR ini tetap aktif saat pindah menu. '
                          'Minta pembayar scan di QR → Scan & Bayar.',
                          style: TextStyle(
                            //ignore: deprecated_member_use
                            color: Colors.amber.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    context.read<QrBloc>().add(CancelQr(state.token));
                    setState(() => _step = 3);
                  },
                  child: const Text(
                    'Batalkan & Ganti Metode',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        // Default: loading
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1a56db)),
        );
      },
    );
  }

  // ── Step 5: Sukses ───────────────────────────────────────────────────────
  Widget _buildStep5Success() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        final success = state is PaymentSuccess ? state : null;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  success != null
                      ? 'Produk ${success.productName} berhasil dibayar'
                      : 'Transaksi berhasil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  success != null ? formatRupiah(success.amount) : '',
                  style: const TextStyle(
                    color: Color(0xFF38bdf8),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                if (success != null) ...[
                  Text(
                    'Ref: ${success.transactionNumber}',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.45),
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
                            amount: success.amount,
                            referenceNumber: success.transactionNumber,
                            productName: success.productName,
                            provider: success.provider,
                            targetNumber: success.targetNumber,
                            targetLabel: _targetLabel,
                            paymentMethod: _paymentMethod == 'saldo'
                                ? 'Saldo KyPay'
                                : 'QR KyPay',
                            resultCode: success.resultCode,
                            resultCodeLabel: success.category == 'token_listrik'
                                ? 'Token Listrik'
                                : success.category == 'voucher_game'
                                ? 'Voucher Code'
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
                        setState(() {
                          _step = 1;
                          _selectedCategory = '';
                          _targetController.clear();
                          _pinController.clear();
                        });
                        context.read<PaymentBloc>().add(ResetPayment());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891b2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Bayar Lagi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0f172a),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ke Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

  void _submitPayment() {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN harus 6 digit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final state = context.read<PaymentBloc>().state;
    if (state is! PaymentProductsLoaded || state.selectedProduct == null) {
      return;
    }

    context.read<PaymentBloc>().add(
      SubmitPayment(
        productCode: state.selectedProduct!['code'],
        targetNumber: _targetController.text.trim(),
        pin: _pinController.text,
      ),
    );
  }
}
