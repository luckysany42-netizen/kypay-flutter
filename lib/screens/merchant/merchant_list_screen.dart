import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../../models/merchant_model.dart';
import 'merchant_input_screen.dart';

/// Halaman list merchant per kategori (muncul saat tap "Lihat semua")
class MerchantListScreen extends StatefulWidget {
  final String categoryCode;
  final String categoryName;

  const MerchantListScreen({
    super.key,
    required this.categoryCode,
    required this.categoryName,
  });

  @override
  State<MerchantListScreen> createState() => _MerchantListScreenState();
}

class _MerchantListScreenState extends State<MerchantListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MerchantBloc>().add(LoadMerchants(categoryCode: widget.categoryCode));
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: BlocBuilder<MerchantBloc, MerchantState>(
        builder: (context, state) {
          if (state is MerchantLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1a56db)));
          }
          if (state is MerchantError) {
            return Center(child: Text(state.message,
              //ignore: deprecated_member_use
              style: TextStyle(color: Colors.white.withOpacity(0.5))));
          }
          if (state is MerchantsLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   3,
                mainAxisSpacing:  20,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: state.merchants.length,
              itemBuilder: (_, i) => _buildItem(state.merchants[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildItem(MerchantModel merchant) {
    return GestureDetector(
      onTap: () {
        context.read<MerchantBloc>().selectMerchant(merchant);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<MerchantBloc>(),
            child: MerchantInputScreen(merchant: merchant),
          ),
        ));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: merchant.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(merchant.logoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(merchant)),
                  )
                : _fallback(merchant),
          ),
          const SizedBox(height: 8),
          Text(merchant.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
            )),
        ],
      ),
    );
  }

  Widget _fallback(MerchantModel m) {
    final emoji = switch (m.category?.code ?? '') {
      'game'    => '🎮',
      'pulsa'   => '📱',
      'tagihan' => '📄',
      'rumah'   => '⚡',
      'hiburan' => '🎵',
      _         => '💳',
    };
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 28)));
  }
}