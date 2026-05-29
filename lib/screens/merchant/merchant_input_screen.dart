import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../../models/merchant_model.dart';
import '../../models/merchant_product_model.dart';
import 'product_select_screen.dart';

/// Layar input nomor HP / ID Game / Nomor Pelanggan
class MerchantInputScreen extends StatefulWidget {
  final MerchantModel merchant;
  const MerchantInputScreen({super.key, required this.merchant});

  @override
  State<MerchantInputScreen> createState() => _MerchantInputScreenState();
}

class _MerchantInputScreenState extends State<MerchantInputScreen> {
  final _inputController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Load produk di background
    context.read<MerchantBloc>().add(LoadProducts(widget.merchant.id));
    _inputController.addListener(_validate);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _validate() {
    final len = _inputController.text.trim().length;
    final min = widget.merchant.inputConfig.minLength;
    final max = widget.merchant.inputConfig.maxLength;
    setState(() => _isValid = len >= min && len <= max);
  }

  void _onNext(List<MerchantProductModel> products) {
    if (!_isValid) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<MerchantBloc>(),
        child: ProductSelectScreen(
          merchant:   widget.merchant,
          inputValue: _inputController.text.trim(),
          products:   products,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.merchant.inputConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.merchant.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: BlocBuilder<MerchantBloc, MerchantState>(
        builder: (context, state) {
          final products = state is ProductsLoaded ? state.products : <MerchantProductModel>[];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Merchant Header ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(
                        _categoryEmoji(widget.merchant.category?.code),
                        style: const TextStyle(fontSize: 28),
                      )),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.merchant.name,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        if (widget.merchant.category != null)
                          Text(widget.merchant.category!.name,
                            //ignore: deprecated_member_use
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Input Label ──────────────────────────────────────────
                Text(cfg.label,
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
                const SizedBox(height: 10),

                // ── Input Field ──────────────────────────────────────────
                TextField(
                  controller: _inputController,
                  keyboardType: cfg.isPhone
                      ? TextInputType.phone
                      : cfg.isAccount
                          ? TextInputType.emailAddress
                          : TextInputType.number,
                  maxLength: cfg.maxLength,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: cfg.hint,
                    //ignore: deprecated_member_use
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    //ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5),
                    ),
                    prefixIcon: Icon(
                      cfg.isPhone   ? Icons.phone_android
                      : cfg.isGameId ? Icons.sports_esports
                      : cfg.isAccount ? Icons.email_outlined
                      : Icons.confirmation_number_outlined,
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.4),
                    ),
                    counterStyle: TextStyle(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                ),

                // ── Info tip ──────────────────────────────────────────────
                if (cfg.isGameId) ...[
                  const SizedBox(height: 10),
                  Container(
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
                        const Icon(Icons.info_outline, color: Color(0xFF1a56db), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID Game bisa ditemukan di profil akun game kamu.',
                            //ignore: deprecated_member_use
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // ── Tombol Lanjut ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (state is MerchantLoading || !_isValid || products.isEmpty)
                        ? null
                        : () => _onNext(products),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a56db),
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state is MerchantLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Lanjut',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryEmoji(String? code) => switch (code ?? '') {
    'game'    => '🎮',
    'pulsa'   => '📱',
    'tagihan' => '📄',
    'rumah'   => '⚡',
    'hiburan' => '🎵',
    _         => '💳',
  };
}