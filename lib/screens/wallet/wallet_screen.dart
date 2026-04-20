import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
// ignore: unused_import
import '../history/history_screen.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback openHistoryTab;

  const WalletScreen({super.key, required this.openHistoryTab});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  bool _copied = false;

  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    context.read<WalletBloc>().add(FetchWallet());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _refreshController.repeat();
    context.read<WalletBloc>().add(FetchWallet());
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _refreshController.stop();
    });
  }

  String formatRupiah(dynamic val) {
    final number = double.tryParse(val.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  IconData getTransactionIconData(String type) {
    switch (type) {
      case 'top_up':
        return Icons.arrow_downward_rounded;
      case 'transfer_in':
        return Icons.arrow_downward_rounded;
      case 'transfer_out':
        return Icons.arrow_upward_rounded;
      case 'payment':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.circle;
    }
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'top_up':
        return 'Top Up';
      case 'transfer_in':
        return 'Transfer Masuk';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'payment':
        return 'Pembayaran';
      default:
        return type;
    }
  }

  Color getTransactionColor(String type) {
    switch (type) {
      case 'top_up':
      case 'transfer_in':
        return Colors.green;
      case 'transfer_out':
      case 'payment':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _copyWalletNumber(String walletNumber) async {
    await Clipboard.setData(ClipboardData(text: walletNumber));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    //ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor wallet tersalin!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Modal Ganti PIN ───────────────────────────────────────────────────────
  void _showChangePinModal() {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0d1829),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ganti PIN KyPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _pinField('PIN Lama', oldPinCtrl),
                const SizedBox(height: 12),
                _pinField('PIN Baru', newPinCtrl),
                const SizedBox(height: 12),
                _pinField('Konfirmasi PIN Baru', confCtrl),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (newPinCtrl.text != confCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN baru tidak cocok'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (newPinCtrl.text.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN harus 6 digit'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            setModalState(() => loading = true);
                            try {
                              // API ganti PIN belum ada, jadi ini cuma simulasi
                              // await ApiService.dio.post('/wallet/set-pin', data: {
                              //   'current_pin': oldPinCtrl.text,
                              //   'pin': newPinCtrl.text,
                              //   'pin_confirmation': confCtrl.text,
                              // });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN berhasil diubah!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal mengubah PIN'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setModalState(() => loading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd97706),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan PIN Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pinField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(color: Colors.white, letterSpacing: 6),
      decoration: InputDecoration(
        labelText: label,
        //ignore: deprecated_member_use
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        counterText: '',
        filled: true,
        //ignore: deprecated_member_use
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFd97706), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoaded || state is WalletError) {
            _refreshController.stop();
          }

          if (state is WalletLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a56db)),
            );
          }

          if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is WalletLoaded) {
            final wallet = state.wallet;
            final transactions = state.transactions;

            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              color: const Color(0xFF1a56db),
              child: CustomScrollView(
                slivers: [
                  // ── Header Card ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a2f5a), Color(0xFF0d2244)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                wallet.walletName,
                                style: TextStyle(
                                  //ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      //ignore: deprecated_member_use
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        //ignore: deprecated_member_use
                                        color: Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => context.read<AuthBloc>().add(
                                      LogoutRequested(),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.5),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Saldo KyPay',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _balanceVisible
                                    ? formatRupiah(wallet.balance)
                                    : 'Rp ••••••••',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _balanceVisible = !_balanceVisible,
                                ),
                                child: Icon(
                                  _balanceVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                      //ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.4),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _copyWalletNumber(wallet.walletNumber),
                            child: Row(
                              children: [
                                Text(
                                  wallet.walletNumber,
                                  style: TextStyle(
                                    //ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _copied ? Icons.check_circle : Icons.copy,
                                  color: _copied
                                      ? Colors.green
                                      //ignore: deprecated_member_use
                                      : Colors.white.withOpacity(0.4),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Actions (4 tombol — tanpa QR, ada Ganti PIN) ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.add_circle_outline,
                            label: 'Top Up',
                            color: const Color(0xFF1a56db),
                            onTap: () => Navigator.pushNamed(context, '/topup'),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.send_outlined,
                            label: 'Transfer',
                            color: const Color(0xFF0891b2),
                            onTap: () =>
                                Navigator.pushNamed(context, '/transfer'),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.grid_view_rounded,
                            label: 'Bayar',
                            color: const Color(0xFFd97706),
                            onTap: () =>
                                Navigator.pushNamed(context, '/payment'),
                          ),
                          const SizedBox(width: 12),
                          // ✅ Ganti PIN (gantikan QR)
                          _buildActionButton(
                            icon: Icons.shield_outlined,
                            label: 'Ganti PIN',
                            color: const Color(0xFF059669),
                            onTap: _showChangePinModal,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Header Transaksi ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaksi Terakhir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Refresh button
                              GestureDetector(
                                onTap: _onRefresh,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    //ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: RotationTransition(
                                    turns: _refreshController,
                                    child: Icon(
                                      Icons.refresh_rounded,
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.6),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.openHistoryTab,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    color: Color(0xFF1a56db),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Transaksi List ───────────────────────────────────────
                  transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    //ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.2),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada transaksi',
                                    style: TextStyle(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final trx = transactions[index];
                              final type = trx['type'] ?? '';
                              final isCredit = [
                                'top_up',
                                'transfer_in',
                              ].contains(type);

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  //ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: getTransactionColor(
                                          type,
                                          //ignore: deprecated_member_use
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        getTransactionIconData(type),
                                        color: getTransactionColor(type),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            getTypeLabel(type),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            trx['description'] ?? '',
                                            style: TextStyle(
                                              //ignore: deprecated_member_use
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            trx['created_at']
                                                    ?.toString()
                                                    .substring(0, 10) ??
                                                '',
                                            style: TextStyle(
                                              //ignore: deprecated_member_use
                                              color: Colors.white.withOpacity(
                                                0.4,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isCredit ? '+' : '-'}${formatRupiah(double.tryParse(trx['amount'].toString()) ?? 0)}',
                                      style: TextStyle(
                                        color: getTransactionColor(type),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: transactions.length > 5
                                ? 5
                                : transactions.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            //ignore: deprecated_member_use
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
