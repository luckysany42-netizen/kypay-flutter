import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kypay/blocs/wallet/wallet_state.dart';
import '../../blocs/transfer/transfer_bloc.dart';
import '../../blocs/transfer/transfer_event.dart';
import '../../blocs/transfer/transfer_state.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../services/api_service.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/qr/qr_bloc.dart';
import '../../blocs/qr/qr_event.dart';
import '../../blocs/qr/qr_state.dart';
import '../../blocs/contact/contact_bloc.dart';
import '../../widgets/struk_widget.dart';
import '../../widgets/money_input_sheet.dart';
import '../../screens/contact/contact_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Kirim Transfer ─────────────────────────
  final _walletNumberController = TextEditingController();
  final _amountController       = TextEditingController();
  final _noteController         = TextEditingController();
  final _pinController          = TextEditingController();
  int    _step                  = 1;
  double _currentBalance        = 0;
  String _receiverWalletNumber  = '';
  String _receiverName          = ''; // ← Simpan nama penerima
  // ignore: avoid_init_to_null
  String? _receiverAvatar       = null; // ← Simpan avatar penerima

  // ── Terima QR ──────────────────────────────
  final _qrAmountController = TextEditingController();
  final _qrDescController   = TextEditingController();

  String formatRupiah(double val) => NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);

  String formatTime(int secs) =>
      '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final ws = context.read<WalletBloc>().state;
    if (ws is WalletLoaded) _currentBalance = ws.wallet.balance;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _walletNumberController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _pinController.dispose();
    _qrAmountController.dispose();
    _qrDescController.dispose();
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
            if (_step > 1 && _tabController.index == 0) {
              setState(() => _step--);
              context.read<TransferBloc>().add(ResetTransfer());
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _tabController.index == 0
              ? (_step == 1
                  ? 'Transfer KyPay'
                  : _step == 2
                      ? 'Konfirmasi Transfer'
                      : 'Transfer Berhasil')
              : 'Terima via QR',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol buka kontak — pakai BlocProvider.value agar
          // ContactBloc dari main.dart digunakan (bukan baru)
          IconButton(
            icon: const Icon(Icons.contacts, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ContactBloc>(),
                    child: const ContactScreen(isSelector: true),
                  ),
                ),
              );
              if (result != null && mounted) {
                _walletNumberController.text = result;
                _searchWallet();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0891b2),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded), text: 'Kirim'),
            Tab(icon: Icon(Icons.qr_code_rounded), text: 'Terima QR'),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TransferBloc, TransferState>(
            listener: (context, state) {
              if (state is TransferSuccess) {
                context.read<WalletBloc>().add(FetchWallet());
                // Refresh kontak otomatis setelah transfer berhasil
                // supaya penerima baru langsung muncul di daftar kontak
                context.read<ContactBloc>().add(FetchContacts());
                setState(() => _step = 3);
              } else if (state is TransferError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
          BlocListener<QrBloc, QrState>(
            listener: (context, state) {
              if (state is QrPaymentReceived) {
                context.read<WalletBloc>().add(FetchWallet());
              }
            },
          ),
        ],
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildKirimTab(), _buildTerimaQrTab()],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 1: KIRIM TRANSFER
  // ══════════════════════════════════════════════════════
  Widget _buildKirimTab() {
    if (_step == 1) return _buildStep1();
    if (_step == 2) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo tersedia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF0891b2), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Saldo tersedia: ${formatRupiah(_currentBalance)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Nomor Wallet Tujuan',
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _walletNumberController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Contoh: KP-2026-XXXXX',
                    hintStyle:
                    //ignore: deprecated_member_use
                        TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    //ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      //ignore: deprecated_member_use
                          BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      //ignore: deprecated_member_use
                          BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF0891b2)),
                    ),
                  ),
                  onSubmitted: (_) => _searchWallet(),
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<TransferBloc, TransferState>(
                builder: (context, state) {
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state is TransferSearching
                          ? null
                          : _searchWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891b2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state is TransferSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          BlocBuilder<TransferBloc, TransferState>(
            builder: (context, state) {
              if (state is TransferSearchError) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    //ignore: deprecated_member_use
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(state.message,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ),
                );
              }

              if (state is TransferReceiverFound) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          //ignore: deprecated_member_use
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          _buildReceiverAvatar(
                            avatarUrl: state.ownerAvatar,
                            name: state.ownerName,
                            radius: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Penerima Ditemukan',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text(state.ownerName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text(state.walletNumber,
                                    style: TextStyle(
                                      //ignore: deprecated_member_use
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: Colors.green),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Jumlah Transfer (Rp)',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final result = await showMoneyInput(
                          context,
                          title: 'Jumlah Transfer',
                          subtitle: 'Saldo: ${formatRupiah(_currentBalance)}',
                          maxValue: _currentBalance,
                          quickAmounts: [25000, 50000, 100000, 200000, 300000, 500000],
                          accentColor: const Color(0xFF0891b2),
                        );
                        if (result != null) {
                          setState(() => _amountController.text = result.toInt().toString());
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rp ',
                                  style: TextStyle(
                                    //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.5), fontSize: 12),
                                ),
                                Text(
                                  _amountController.text.isEmpty
                                      ? '0'
                                      : formatRupiah(
                                          double.tryParse(_amountController.text) ?? 0),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Icon(Icons.edit_outlined,
                                color: Color(0xFF0891b2), size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text('Catatan (opsional)',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Contoh: bayar makan siang',
                        hintStyle: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        //ignore: deprecated_member_use
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF0891b2)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          //ignore: deprecated_member_use
                            color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Transfer bersifat instan dan tidak dapat dibatalkan.',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                  color: Colors.orange.withOpacity(0.9),
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goToConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0891b2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Lanjut',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final amount = double.tryParse(_amountController.text) ?? 0;

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
                // Tampilkan avatar penerima dengan image jika ada
                _receiverAvatar != null && _receiverAvatar!.isNotEmpty
                    ? _buildReceiverAvatar(
                        avatarUrl: _receiverAvatar,
                        name: _receiverName,
                        radius: 30,
                      )
                    : CircleAvatar(
                        backgroundColor: const Color(0xFF0891b2),
                        radius: 30,
                        child: Text(
                          _receiverName.isNotEmpty
                              ? _receiverName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 12),
                Text(_receiverName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(_receiverWalletNumber,
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13)),
                const Divider(color: Colors.white12, height: 32),
                _buildSummaryRow('Jumlah', formatRupiah(amount),
                    valueColor: const Color(0xFF0891b2)),
                const SizedBox(height: 10),
                _buildSummaryRow('Biaya Transfer', 'Gratis',
                    valueColor: Colors.green),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                _buildSummaryRow('Total Dipotong', formatRupiah(amount),
                    valueColor: Colors.red, isBold: true),
                const SizedBox(height: 10),
                _buildSummaryRow('Saldo Setelah',
                    formatRupiah(_currentBalance - amount),
                    valueColor: Colors.white70),
                if (_noteController.text.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    children: [
                      Text('Catatan: ',
                          style: TextStyle(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13)),
                      Text(_noteController.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Masukkan PIN KyPay',
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600)),
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
                letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.3), letterSpacing: 8),
              filled: true,
              //ignore: deprecated_member_use
              fillColor: Colors.white.withOpacity(0.08),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                //ignore: deprecated_member_use
                    BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                //ignore: deprecated_member_use
                    BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0891b2)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          BlocBuilder<TransferBloc, TransferState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      state is TransferLoading ? null : _submitTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891b2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state is TransferLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text('Konfirmasi Transfer',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (context, state) {
        final success = state is TransferSuccess ? state : null;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 50),
                ),
                const SizedBox(height: 24),
                const Text('Transfer Berhasil!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Dikirim ke ${success?.receiverName ?? ''}',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14)),
                const SizedBox(height: 8),
                Text(formatRupiah(success?.amount ?? 0),
                    style: const TextStyle(
                        color: Color(0xFF0891b2),
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Ref: ${success?.referenceNumber ?? '-'}',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12)),
                const SizedBox(height: 40),

                // Tombol Lihat Struk
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showStrukModal(
                        context,
                        StrukWidget(
                          type: 'transfer',
                          amount: success?.amount ?? 0,
                          referenceNumber:
                              success?.referenceNumber ?? '-',
                          receiverName: success?.receiverName ?? '',
                          receiverWallet: _receiverWalletNumber,
                          note: _noteController.text.isEmpty
                              ? null
                              : _noteController.text,
                          tanggal: DateTime.now(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long,
                        color: Colors.white70, size: 18),
                    label: const Text('Lihat Struk',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<TransferBloc>().add(ResetTransfer());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891b2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kembali ke Wallet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB 2: TERIMA QR
  // ══════════════════════════════════════════════════════
  Widget _buildTerimaQrTab() {
    return BlocBuilder<QrBloc, QrState>(
      builder: (context, state) {
        if (state is QrGenerated) return _buildQrDisplay(state);
        if (state is QrPaymentReceived) return _buildTerimaSuccess(state);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: const Color(0xFF0891b2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    //ignore: deprecated_member_use
                      color: const Color(0xFF0891b2).withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF0891b2), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buat QR untuk menerima transfer dari pengguna KyPay lain.',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text('Jumlah yang Diminta',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final result = await showMoneyInput(
                    context,
                    title: 'Jumlah yang Diminta',
                    maxValue: null,
                    quickAmounts: [25000, 50000, 100000, 200000, 300000, 500000],
                    accentColor: const Color(0xFF0891b2),
                  );
                  if (result != null) {
                    setState(() => _qrAmountController.text = result.toInt().toString());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.5), fontSize: 12),
                          ),
                          Text(
                            _qrAmountController.text.isEmpty
                                ? '0'
                                : formatRupiah(
                                    double.tryParse(_qrAmountController.text) ?? 0),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_outlined,
                          color: Color(0xFF0891b2), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [10000, 20000, 50000, 100000].map((amt) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _qrAmountController.text = amt.toString(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          amt >= 1000 ? '${amt ~/ 1000}rb' : '$amt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text('Keterangan (opsional)',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _qrDescController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contoh: bayar makan siang',
                  hintStyle:
                  //ignore: deprecated_member_use
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  //ignore: deprecated_member_use
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF0891b2), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state is QrLoading ? null : _generateQr,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891b2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state is QrLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text('Buat QR Code',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrDisplay(QrGenerated state) {
    final isExpiringSoon = state.secondsLeft <= 60;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  //ignore: deprecated_member_use
                  color: const Color(0xFF0891b2).withOpacity(0.3),
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
                        color: const Color(0xFF0891b2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 6),
                    const Text('KyPay Transfer',
                        style: TextStyle(
                            color: Color(0xFF0891b2),
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
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
                      color: Color(0xFF0891b2)),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0f1b35)),
                ),
                const SizedBox(height: 12),
                Text(formatRupiah(state.amount),
                    style: const TextStyle(
                        color: Color(0xFF0891b2),
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text('Kode QR',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.5),
                        fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(state.token,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: state.token));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Kode QR disalin'),
                                  duration: Duration(seconds: 1)),
                            );
                          }
                        },
                        child: const Icon(Icons.copy,
                            size: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (state.description != null)
                  Text(state.description!,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                Icon(Icons.timer,
                    color:
                        isExpiringSoon ? Colors.red : Colors.white54,
                    size: 18),
                const SizedBox(width: 8),
                Text('Berlaku: ${formatTime(state.secondsLeft)}',
                    style: TextStyle(
                        color: isExpiringSoon
                            ? Colors.red
                            : Colors.white70,
                        fontWeight: FontWeight.w600)),
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
                      color: Color(0xFF0891b2), strokeWidth: 2)),
              const SizedBox(width: 8),
              Text('Menunggu pembayaran...',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13)),
            ],
          ),

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
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR ini tetap aktif saat kamu pindah ke menu lain. '
                    'Minta pembayar untuk scan di menu QR → Scan & Bayar.',
                    style: TextStyle(
                      //ignore: deprecated_member_use
                        color: Colors.amber.withOpacity(0.9),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () =>
                context.read<QrBloc>().add(CancelQr(state.token)),
            child: const Text('Batalkan QR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTerimaSuccess(QrPaymentReceived state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 52),
            ),
            const SizedBox(height: 20),
            const Text('Pembayaran Diterima!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(formatRupiah(state.amount),
                style: const TextStyle(
                    color: Color(0xFF0891b2),
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  showStrukModal(
                    context,
                    StrukWidget(
                      type: 'transfer',
                      amount: state.amount,
                      referenceNumber: state.transactionNumber,
                      receiverName: 'Pembayaran QR',
                      tanggal: DateTime.now(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.receipt_long,
                    color: Colors.white70, size: 18),
                label: const Text('Lihat Struk',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    context.read<QrBloc>().add(ResetQr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891b2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Buat QR Baru',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────
  Widget _buildSummaryRow(String label, String value,
      {Color valueColor = Colors.white, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(value,
            style: TextStyle(
              color: valueColor,
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            )),
      ],
    );
  }

  Widget _buildReceiverAvatar({
    required String? avatarUrl,
    required String name,
    double radius = 22,
  }) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // Build full URL dari avatar path
      final fullUrl = _buildAvatarUrl(avatarUrl);

      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.green,
        child: ClipOval(
          child: Image.network(
            fullUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  /// Build full avatar URL dari response backend
  /// Backend kirim: "/uploads/avatars/abc123.jpg"
  /// Output: "http://[IP]:8000/uploads/avatars/abc123.jpg"
  String _buildAvatarUrl(String avatar) {
    if (avatar.startsWith('http')) return avatar; // Sudah URL lengkap
    
    final base = ApiService.baseUrl.replaceAll('/api', '');
    
    if (avatar.startsWith('/uploads')) {
      // Relative path dari backend
      return '$base$avatar';
    } else {
      // Hanya filename (fallback)
      return '$base/uploads/avatars/$avatar';
    }
  }

  void _searchWallet() {    final number = _walletNumberController.text.trim();
    if (number.isEmpty) return;
    context.read<TransferBloc>().add(SearchWallet(number));
  }

  void _goToConfirmation() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Minimal transfer Rp 1.000'),
          backgroundColor: Colors.orange));
      return;
    }
    if (amount > _currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saldo tidak mencukupi'),
          backgroundColor: Colors.red));
      return;
    }
    final state = context.read<TransferBloc>().state;
    if (state is TransferReceiverFound) {
      _receiverWalletNumber = state.walletNumber;
      _receiverName = state.ownerName;
      _receiverAvatar = state.ownerAvatar;
    }
    _pinController.clear();
    setState(() => _step = 2);
  }

  void _submitTransfer() {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PIN harus 6 digit'),
          backgroundColor: Colors.orange));
      return;
    }
    context.read<TransferBloc>().add(SubmitTransfer(
      receiverWalletNumber: _receiverWalletNumber,
      amount: double.tryParse(_amountController.text) ?? 0,
      pin:    _pinController.text,
      note:   _noteController.text.isEmpty ? null : _noteController.text,
    ));
  }

  void _generateQr() {
    final amount = double.tryParse(_qrAmountController.text) ?? 0;
    if (amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Minimal Rp 1.000'),
          backgroundColor: Colors.orange));
      return;
    }
    context.read<QrBloc>().add(GenerateQrTransfer(
      amount: amount,
      description: _qrDescController.text.trim().isEmpty
          ? null
          : _qrDescController.text.trim(),
    ));
  }
}