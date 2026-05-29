import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../merchant/payment_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchTransactions());
    context.read<MerchantBloc>().add(LoadMerchantTransactions());
  }

  String formatRupiah(dynamic val) {
    final number = double.tryParse(val.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Riwayat Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            //ignore: deprecated_member_use
            icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.6)),
            onPressed: () {
              context.read<WalletBloc>().add(FetchTransactions());
              context.read<MerchantBloc>().add(LoadMerchantTransactions());
            },
          ),
        ],
      ),
      body: _buildCombinedList(),
    );
  }

  // ── Combined transaction list dari wallet dan merchant ─────────────────────
  Widget _buildCombinedList() {
    return BlocListener<MerchantBloc, MerchantState>(
      listener: (context, state) {
        // Rebuild ketika merchant transactions berubah
        if (state is MerchantTransactionsLoaded) {
          setState(() {});
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, walletState) {
          return BlocBuilder<MerchantBloc, MerchantState>(
            builder: (context, merchantState) {
              // Kumpulkan semua transaksi
              final walletTrx = walletState is WalletLoaded
                  ? walletState.transactions
                  : [];
              final merchantTrx = merchantState is MerchantTransactionsLoaded
                  ? merchantState.transactions
                  : [];

              // Tandai dengan source
              final allTrx = <Map<String, dynamic>>[
                ...walletTrx.map((t) => {...(t as Map<String, dynamic>), 'source': 'wallet'}),
                ...merchantTrx.map((t) => {...(t as Map<String, dynamic>), 'source': 'merchant'}),
              ];

              // Filter berdasarkan tipe
              final filtered = _selectedType == 'all'
                  ? allTrx
                  : allTrx.where((t) {
                      final source = t['source'] ?? '';
                      if (source == 'merchant') {
                        // Merchant transactions punya type 'payment'
                        return t['type'] == _selectedType;
                      }
                      return t['type'] == _selectedType;
                    }).toList();

              if (walletState is WalletLoading &&
                  merchantState is MerchantLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1a56db)));
              }

              return Column(
                children: [
                  // Filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        //ignore: deprecated_member_use
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1a2a4a),
                          items: [
                            _dropdownItem('all',          'Semua Tipe'),
                            _dropdownItem('top_up',       'Top Up'),
                            _dropdownItem('transfer_in',  'Transfer Masuk'),
                            _dropdownItem('transfer_out', 'Transfer Keluar'),
                            _dropdownItem('payment',      'Pembayaran & Layanan Digital'),
                          ],
                          onChanged: (val) => setState(() => _selectedType = val ?? 'all'),
                          icon: Icon(Icons.unfold_more_rounded,
                            //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? _emptyState('Tidak ada transaksi')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final trx = filtered[i];
                              final source = trx['source'] ?? '';
                              return source == 'merchant'
                                  ? _merchantTrxCard(trx)
                                  : _walletTrxCard(trx);
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }



  // ── Wallet transaction card ────────────────────────────────────────────────
  Widget _walletTrxCard(Map<String, dynamic> trx) {
    final type     = trx['type'] ?? '';
    final isCredit = ['top_up', 'transfer_in'].contains(type);
    final color    = isCredit ? Colors.green : Colors.red;
    
    // Ensure source is marked
    if (trx['source'] == null) trx['source'] = 'wallet';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
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
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getTypeLabel(trx),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(trx['description'] ?? '',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(trx['created_at']?.toString().substring(0, 10) ?? '',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${formatRupiah(double.tryParse(trx['amount'].toString()) ?? 0)}',
                style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              _statusBadge('Sukses', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  // ── Merchant transaction card ──────────────────────────────────────────────
  Widget _merchantTrxCard(Map<String, dynamic> trx) {
    final status      = trx['status'] ?? 'pending';
    final statusColor = _statusColor(status);
    final statusLabel = trx['status_label'] ?? _statusLabelLocal(status);
    
    // Ensure source is marked
    if (trx['source'] == null) trx['source'] = 'merchant';

    return GestureDetector(
      onTap: () {
        // Tap untuk lihat struk
        if (status == 'success') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<MerchantBloc>()),
                BlocProvider.value(value: context.read<WalletBloc>()),
              ],
              child: PaymentResultScreen(
                receiptData: {
                  'merchant_name':      trx['merchant_name'],
                  'product_name':       trx['product_name'],
                  'input_value':        trx['input_value'],
                  'total_amount':       trx['total_amount'],
                  'admin_fee':          0,
                  'provider_reference': trx['provider_reference'] ?? '-',
                  'status_label':       statusLabel,
                  'created_at':         trx['created_at'],
                  'transaction_id':     trx['id']?.toString(),
                },
                isSuccess: true,
              ),
            ),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          //ignore: deprecated_member_use
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            // Icon kategori merchant
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trx['type_label'] ?? 'Layanan Digital',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(trx['description'] ?? '',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(trx['created_at']?.toString().substring(0, 10) ?? '',
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${formatRupiah(double.tryParse(trx['total_amount'].toString()) ?? 0)}',
                  style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                _statusBadge(statusLabel, statusColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  DropdownMenuItem<String> _dropdownItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Text(label,
        //ignore: deprecated_member_use
        style: TextStyle(color: Colors.white.withOpacity(0.8))),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
        style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.2), size: 64),
          const SizedBox(height: 16),
          Text(message,
            //ignore: deprecated_member_use
            style: TextStyle(color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  String _getTypeLabel(Map<String, dynamic> trx) {
    final source = trx['source'] ?? '';
    
    if (source == 'merchant') {
      // Untuk merchant, gunakan type_label dari API atau product_name
      return trx['type_label'] ?? trx['product_name'] ?? 'Layanan Digital';
    }
    
    // Untuk wallet
    final type = trx['type'] ?? '';
    switch (type) {
      case 'top_up':       return 'Top Up';
      case 'transfer_in':  return 'Transfer Masuk';
      case 'transfer_out': return 'Transfer Keluar';
      case 'payment':      return 'Pembayaran';
      default:             return type;
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'success'    => Colors.green,
      'failed'     => Colors.red,
      'refunded'   => Colors.purple,
      'processing' => Colors.blue,
      _            => Colors.orange,
    };
  }

  String _statusLabelLocal(String status) {
    return switch (status) {
      'success'    => 'Berhasil',
      'failed'     => 'Gagal',
      'refunded'   => 'Dikembalikan',
      'processing' => 'Diproses',
      _            => 'Menunggu',
    };
  }
}