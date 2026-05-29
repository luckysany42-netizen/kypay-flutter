import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../models/merchant_model.dart';
import '../../models/merchant_product_model.dart';
import 'payment_confirm_screen.dart';

/// Layar pilih nominal/paket produk
class ProductSelectScreen extends StatefulWidget {
  final MerchantModel              merchant;
  final String                     inputValue;
  final List<MerchantProductModel> products;

  const ProductSelectScreen({
    super.key,
    required this.merchant,
    required this.inputValue,
    required this.products,
  });

  @override
  State<ProductSelectScreen> createState() => _ProductSelectScreenState();
}

class _ProductSelectScreenState extends State<ProductSelectScreen> {
  MerchantProductModel? _selected;
  String? _activeTag;

  List<String> get _tags {
    final tags = widget.products
        .map((p) => p.categoryTag)
        .whereType<String>()
        .toSet()
        .toList();
    return tags;
  }

  List<MerchantProductModel> get _filtered {
    if (_activeTag == null) return widget.products;
    return widget.products.where((p) => p.categoryTag == _activeTag).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Input value summary ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                //ignore: deprecated_member_use
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.4), size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.merchant.inputConfig.label,
                        //ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      Text(widget.inputValue,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Tag filter ─────────────────────────────────────────────────
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _tagChip('Semua', _activeTag == null, () => setState(() => _activeTag = null)),
                  ..._tags.map((t) => _tagChip(
                    t[0].toUpperCase() + t.substring(1),
                    _activeTag == t,
                    () => setState(() => _activeTag = t),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Pilih Nominal',
              style: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
          ),
          const SizedBox(height: 12),

          // ── Product Grid ───────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   2,
                mainAxisSpacing:  12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final p       = _filtered[i];
                final isSelected = _selected?.id == p.id;
                return GestureDetector(
                  onTap: () => setState(() => _selected = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          //ignore: deprecated_member_use
                          ? const Color(0xFF1a56db).withOpacity(0.2)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1a56db)
                            //ignore: deprecated_member_use
                            : Colors.white.withOpacity(0.08),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),//ignore: deprecated_member_use
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          )),
                        const SizedBox(height: 2),
                        Text(fmt.format(p.totalPrice),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF60a5fa)
                                //ignore: deprecated_member_use
                                : Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                        if (p.validity != null)
                          Text(p.validity!,
                            //ignore: deprecated_member_use
                            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Tombol Lanjut ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selected == null ? null : () {
                  context.read<MerchantBloc>().selectProduct(_selected!);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<MerchantBloc>(),
                      child: PaymentConfirmScreen(
                        merchant:   widget.merchant,
                        product:    _selected!,
                        inputValue: widget.inputValue,
                      ),
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selected == null ? 'Pilih Nominal Dulu' : 'Lanjut Bayar',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: selected ? const Color(0xFF1a56db).withOpacity(0.2) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            //ignore: deprecated_member_use
            color: selected ? const Color(0xFF1a56db) : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label,
          style: TextStyle(
            color: selected ? const Color(0xFF1a56db) : Colors.white.withOpacity(0.6),//ignore: deprecated_member_use
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          )),
      ),
    );
  }
}