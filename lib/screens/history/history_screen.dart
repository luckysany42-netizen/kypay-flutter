import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
 
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
 
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
 
class _HistoryScreenState extends State<HistoryScreen> {
 
  String formatRupiah(dynamic val) {
    final number = double.tryParse(val.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }
 
  String getTypeLabel(String type) {
    switch (type) {
      case 'top_up':       return 'Top Up';
      case 'transfer_in':  return 'Transfer Masuk';
      case 'transfer_out': return 'Transfer Keluar';
      case 'payment':      return 'Pembayaran';
      default:             return type;
    }
  }
 
  Color getTransactionColor(String type) {
    switch (type) {
      case 'top_up':
      case 'transfer_in':  return Colors.green;
      case 'transfer_out':
      case 'payment':      return Colors.red;
      default:             return Colors.grey;
    }
  }
 
  IconData getTransactionIconData(String type) {
    switch (type) {
      case 'top_up':       return Icons.arrow_downward_rounded;
      case 'transfer_in':  return Icons.arrow_downward_rounded;
      case 'transfer_out': return Icons.arrow_upward_rounded;
      case 'payment':      return Icons.shopping_cart_rounded;
      default:             return Icons.circle;
    }
  }
 
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchTransactions());
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
            onPressed: () => context.read<WalletBloc>().add(FetchTransactions()),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a56db)));
          }
 
          if (state is WalletLoaded) {
            final transactions = state.transactions;
 
            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.2), size: 64),
                    const SizedBox(height: 16),
                    Text('Belum ada transaksi',
                    //ignore: deprecated_member_use
                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              );
            }
 
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final trx  = transactions[index];
                final type = trx['type'] ?? '';
                final isCredit = ['top_up', 'transfer_in'].contains(type);
 
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
                          color: getTransactionColor(type).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(getTransactionIconData(type),
                          color: getTransactionColor(type), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getTypeLabel(type),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(trx['description'] ?? '',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              trx['created_at']?.toString().substring(0, 10) ?? '',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.3), fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? '+' : '-'}${formatRupiah(double.tryParse(trx['amount'].toString()) ?? 0)}',
                            style: TextStyle(
                              color: getTransactionColor(type),
                              fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              //ignore: deprecated_member_use
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Sukses',
                              style: TextStyle(
                                color: Colors.green, fontSize: 10,
                                fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
 
          return const SizedBox();
        },
      ),
    );
  }
}