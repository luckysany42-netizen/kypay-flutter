import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kypay/models/merchant_model.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../blocs/topup/topup_bloc.dart';
import '../../blocs/topup/topup_state.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../../widgets/struk_widget.dart';
import '../merchant/merchant_home_screen.dart';
import '../merchant/merchant_input_screen.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback openHistoryTab;
  const WalletScreen({super.key, required this.openHistoryTab});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;
  bool _copied         = false;
  List<MerchantModel> _cachedMerchants = [];

  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    context.read<WalletBloc>().add(FetchWallet(topUpBloc: context.read<TopUpBloc>()));

    final merchantState = context.read<MerchantBloc>().state;
    if (merchantState is FeaturedLoaded) {
      _cachedMerchants = merchantState.merchants;
    } else {
      context.read<MerchantBloc>().add(LoadFeatured());
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _refreshController.repeat();
    context.read<WalletBloc>().add(FetchWallet(topUpBloc: context.read<TopUpBloc>()));
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _refreshController.stop();
    });
  }

  String formatRupiah(dynamic val) {
    final number = double.tryParse(val.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  IconData _getTrxIcon(String type) {
    switch (type) {
      case 'top_up':      return Icons.arrow_downward_rounded;
      case 'transfer_in': return Icons.arrow_downward_rounded;
      case 'transfer_out':return Icons.arrow_upward_rounded;
      case 'payment':     return Icons.shopping_cart_rounded;
      default:            return Icons.circle;
    }
  }

  String _getTrxLabel(String type) {
    switch (type) {
      case 'top_up':       return 'Top Up';
      case 'transfer_in':  return 'Transfer Masuk';
      case 'transfer_out': return 'Transfer Keluar';
      case 'payment':      return 'Pembayaran';
      default:             return type;
    }
  }

  Color _getTrxColor(String type) {
    switch (type) {
      case 'top_up':
      case 'transfer_in':  return Colors.green;
      case 'transfer_out':
      case 'payment':      return Colors.red;
      default:             return Colors.grey;
    }
  }

  void _copyWalletNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    //ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Nomor wallet tersalin!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));
  }

  void _goToAllMerchants() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<MerchantBloc>(),
        child: const MerchantHomeScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MerchantBloc, MerchantState>(
            listener: (context, state) {
              if (state is FeaturedLoaded) {
                setState(() => _cachedMerchants = state.merchants);
              }
            },
          ),
          // BARU: listener untuk popup top up approved
          BlocListener<TopUpBloc, TopUpState>(
            listener: (context, state) {
              if (state is TopUpApproved) {
                _showTopUpApprovedPopup(context, state);
              } else if (state is TopUpRejected) {
                _showTopUpRejectedPopup(context, state);
              }
            },
          ),
        ],
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state is WalletLoaded || state is WalletError) {
              _refreshController.stop();
            }

            if (state is WalletLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1a56db)));
            }

            if (state is WalletError) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _onRefresh, child: const Text('Coba Lagi')),
                ],
              ));
            }

            if (state is WalletLoaded) {
              final wallet       = state.wallet;
              final transactions = state.transactions;

              return RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                color: const Color(0xFF1a56db),
                child: SafeArea(
                  child: CustomScrollView(
                    slivers: [

                    // ── SALDO CARD — tombol Top Up & Transfer di dalam card ──
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1a2f5a), Color(0xFF0d2244)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          //ignore: deprecated_member_use
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // ── Kiri: info saldo ──────────────────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Text(wallet.walletName,
                                        style: TextStyle(
                                          //ignore: deprecated_member_use
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        )),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          //ignore: deprecated_member_use
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          //ignore: deprecated_member_use
                                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                                        ),
                                        child: const Text('AKTIF',
                                          style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
                                        child: Icon(Icons.logout,
                                          //ignore: deprecated_member_use
                                          color: Colors.white.withOpacity(0.4), size: 17),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Label
                                  Text('Saldo KyPay',
                                    style: TextStyle(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                  const SizedBox(height: 4),

                                  // Nominal
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _balanceVisible
                                              ? formatRupiah(wallet.balance)
                                              : 'Rp ••••••',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                                        child: Icon(
                                          _balanceVisible ? Icons.visibility : Icons.visibility_off,
                                          //ignore: deprecated_member_use
                                          color: Colors.white.withOpacity(0.4), size: 18),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Nomor wallet
                                  GestureDetector(
                                    onTap: () => _copyWalletNumber(wallet.walletNumber),
                                    child: Row(
                                      children: [
                                        Text(wallet.walletNumber,
                                          style: TextStyle(
                                            //ignore: deprecated_member_use
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 12, letterSpacing: 1,
                                          )),
                                        const SizedBox(width: 6),
                                        Icon(
                                          _copied ? Icons.check_circle : Icons.copy,
                                          color: _copied ? Colors.green
                                              //ignore: deprecated_member_use
                                              : Colors.white.withOpacity(0.3),
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            // ── Kanan: tombol Top Up & Transfer ──────────
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _sideButton(
                                  icon:  Icons.add_circle_outline,
                                  label: 'Top Up',
                                  color: const Color(0xFF1a56db),
                                  onTap: () => Navigator.pushNamed(context, '/topup'),
                                ),
                                const SizedBox(height: 10),
                                _sideButton(
                                  icon:  Icons.send_outlined,
                                  label: 'Transfer',
                                  color: const Color(0xFF0891b2),
                                  onTap: () => Navigator.pushNamed(context, '/transfer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // ── LAYANAN DIGITAL ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Layanan Digital',
                              style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: _goToAllMerchants,
                              child: const Text('Lihat Semua',
                                style: TextStyle(
                                  color: Color(0xFF1a56db), fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMerchantGrid(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── TRANSAKSI TERAKHIR ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transaksi Terakhir',
                              style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _onRefresh,
                                  child: Container(
                                    width: 32, height: 32,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      //ignore: deprecated_member_use
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: RotationTransition(
                                      turns: _refreshController,
                                      child: Icon(Icons.refresh_rounded,
                                        //ignore: deprecated_member_use
                                        color: Colors.white.withOpacity(0.6), size: 18),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.openHistoryTab,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Lihat Semua',
                                    style: TextStyle(color: Color(0xFF1a56db), fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    transactions.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_outlined,
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.2), size: 48),
                                    const SizedBox(height: 12),
                                    Text('Belum ada transaksi',
                                      //ignore: deprecated_member_use
                                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final trx      = transactions[index];
                                final type     = trx['type'] ?? '';
                                final isCredit = ['top_up','transfer_in'].contains(type);

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    //ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          //ignore: deprecated_member_use
                                          color: _getTrxColor(type).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(_getTrxIcon(type),
                                          color: _getTrxColor(type), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_getTrxLabel(type),
                                              style: const TextStyle(
                                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(trx['description'] ?? '',
                                              style: TextStyle(
                                                //ignore: deprecated_member_use
                                                color: Colors.white.withOpacity(0.4), fontSize: 11),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(trx['created_at']?.toString().substring(0, 10) ?? '',
                                              style: TextStyle(
                                                //ignore: deprecated_member_use
                                                color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isCredit ? '+' : '-'}${formatRupiah(double.tryParse(trx['amount'].toString()) ?? 0)}',
                                        style: TextStyle(
                                          color: _getTrxColor(type),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: transactions.length > 5 ? 5 : transactions.length,
                            ),
                          ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showTopUpApprovedPopup(BuildContext context, TopUpApproved state) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    // Simpan context dan state untuk digunakan di dalam dialog
    final savedContext = context;
    final savedState = state;

    // Tampilkan popup notifikasi terlebih dahulu
    showDialog(
      context: savedContext,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0d1829),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon animasi
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, val, child) => Transform.scale(scale: val, child: child),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                    //ignore: deprecated_member_use
                    border: Border.all(color: Colors.green.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 48),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Top Up Berhasil!',
                style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 8),

              Text(
                'Saldo kamu sudah bertambah',
                //ignore: deprecated_member_use
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),

              const SizedBox(height: 16),

              // Nominal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: const Color(0xFF1a56db).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  //ignore: deprecated_member_use
                  border: Border.all(color: const Color(0xFF1a56db).withOpacity(0.3)),
                ),
                child: Column(children: [
                  Text(fmt.format(savedState.amount),
                    style: const TextStyle(
                      color: Color(0xFF1a56db), fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('via ${savedState.methodName}',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 24),

              // Tombol Lihat Struk
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(savedContext, rootNavigator: true).pop(); // dismiss popup sementara
                    Future.delayed(const Duration(milliseconds: 300), () {
                      // Tampilkan struk, dan setelah ditutup, tampilkan popup lagi
                      showStrukModal(
                        // ignore: use_build_context_synchronously
                        savedContext,
                        StrukWidget(
                          type:            'top_up',
                          amount:          savedState.amount,
                          referenceNumber: savedState.referenceNumber,
                          productName:     'Top Up Saldo KyPay',
                          provider:        savedState.methodName,
                          targetNumber:    '-',
                          targetLabel:     'Metode',
                          paymentMethod:   savedState.methodName,
                          tanggal:         _parseDate(savedState.approvedAt),
                        ),
                      ).then((_) {
                        // Setelah struk ditutup, tampilkan popup lagi
                        // ignore: use_build_context_synchronously
                        _showTopUpApprovedPopup(savedContext, savedState);
                      });
                    });
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Lihat Struk'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1a56db),
                    side: const BorderSide(color: Color(0xFF1a56db)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol OK
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(savedContext, rootNavigator: true).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a56db),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK, Terima Kasih!',
                    style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopUpRejectedPopup(BuildContext context, TopUpRejected state) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0d1829),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Icon animasi ────────────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, val, child) => Transform.scale(scale: val, child: child),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    //ignore: deprecated_member_use
                    border: Border.all(color: Colors.red.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 48),
                ),
              ),

              const SizedBox(height: 20),

              // ── Title ───────────────────────────────────────────────────
              const Text(
                'Top Up Ditolak',
                style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 8),

              Text(
                'Pengajuan kamu tidak dapat disetujui',
                //ignore: deprecated_member_use
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),

              const SizedBox(height: 16),

              // ── Nominal ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Column(children: [
                  Text(
                    fmt.format(state.amount),
                    style: const TextStyle(
                      color: Colors.red, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'via ${state.methodName}',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Alasan penolakan dari admin ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.orange.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 15),
                      const SizedBox(width: 6),
                      const Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      state.adminNote,
                      style: TextStyle(
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── No. Referensi ────────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.tag,
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.3), size: 13),
                const SizedBox(width: 4),
                Text(
                  'Ref: ${state.referenceNumber}',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                ),
              ]),

              const SizedBox(height: 8),

              // ── Info pengajuan ulang ──────────────────────────────────────
              Text(
                'Kamu dapat mengajukan top up ulang\nsetelah memperbaiki bukti transfer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // ── Tombol OK ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  // ── Merchant grid (6 featured + QR + Lihat Semua) ─────────────────────────
  Widget _buildMerchantGrid() {
    if (_cachedMerchants.isEmpty) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
        children: List.generate(8, (_) => Column(children: [
          Container(width: 58, height: 58,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            )),
          const SizedBox(height: 6),
          Container(width: 44, height: 10,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(4),
            )),
        ])),
      );
    }

    final displayed = _cachedMerchants.take(6).toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        ...displayed.map(_merchantItem),
        _qrItem(),
        _lihatSemuaItem(),
      ],
    );
  }

  Widget _merchantItem(MerchantModel m) {
    return GestureDetector(
      onTap: () {
        context.read<MerchantBloc>().selectMerchant(m);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<MerchantBloc>(),
            child: MerchantInputScreen(merchant: m),
          ),
        ));
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            //ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: m.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(m.logoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _emojiIcon(m)))
              : _emojiIcon(m),
        ),
        const SizedBox(height: 6),
        Text(m.name,
          maxLines: 2, textAlign: TextAlign.center,
          style: TextStyle(
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8),
            fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)),
      ]),
    );
  }

  Widget _qrItem() {
    return GestureDetector(
      onTap: () {
        // Trigger QR via bottom nav index 2
        // Cara paling simple: navigasi ke QrScreen langsung
        Navigator.pushNamed(context, '/qr-payment');
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: const Color(0xFF1a56db).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            //ignore: deprecated_member_use
            border: Border.all(color: const Color(0xFF1a56db).withOpacity(0.3)),
          ),
          child: const Center(child: Icon(Icons.qr_code_scanner_rounded,
            color: Color(0xFF1a56db), size: 28)),
        ),
        const SizedBox(height: 6),
        const Text('Scan QR',
          maxLines: 2, textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF1a56db),
            fontSize: 11, fontWeight: FontWeight.w600, height: 1.3)),
      ]),
    );
  }

  Widget _lihatSemuaItem() {
    return GestureDetector(
      onTap: _goToAllMerchants,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            //ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Center(child: Icon(Icons.grid_view_rounded,
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8), size: 26)),
        ),
        const SizedBox(height: 6),
        Text('Lihat\nSemua',
          maxLines: 2, textAlign: TextAlign.center,
          style: TextStyle(
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.7),
            fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)),
      ]),
    );
  }

  Widget _emojiIcon(MerchantModel m) {
    final emoji = switch (m.category?.code ?? '') {
      'game'    => '🎮',
      'pulsa'   => '📱',
      'tagihan' => '📄',
      'rumah'   => '⚡',
      'hiburan' => '🎵',
      _         => '💳',
    };
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 26)));
  }

  // ── Tombol vertikal di kanan saldo ─────────────────────────────────────────
  Widget _sideButton({
    required IconData icon,
    required String   label,
    required Color    color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          //ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}