import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/merchant/merchant_bloc.dart';
import '../blocs/merchant/merchant_event.dart';
import '../blocs/merchant/merchant_state.dart';
import '../models/merchant_model.dart';
import '../screens/merchant/merchant_home_screen.dart';
import '../screens/merchant/merchant_input_screen.dart';

/**
 * ═══════════════════════════════════════════════════════
 * PETUNJUK: Tambahkan widget ini ke Home Screen
 * ═══════════════════════════════════════════════════════
 * 
 * 1. Di main.dart atau BlocProvider utama, tambahkan:
 *    BlocProvider(create: (_) => MerchantBloc()),
 * 
 * 2. Di home screen, tambahkan MerchantSectionWidget()
 *    di bawah tombol-tombol (TopUp, Transfer, Bayer, Ganti PIN)
 * 
 * 3. Tombol "Bayer" yang ada bisa diarahkan ke MerchantHomeScreen
 * ═══════════════════════════════════════════════════════
 */

/// Widget section merchant untuk Home Screen
/// Menampilkan 7 merchant featured + tombol "Lihat Semua"
class MerchantSectionWidget extends StatefulWidget {
  const MerchantSectionWidget({super.key});

  @override
  State<MerchantSectionWidget> createState() => _MerchantSectionWidgetState();
}

class _MerchantSectionWidgetState extends State<MerchantSectionWidget> {
  List<MerchantModel> _cachedMerchants = [];

  @override
  void initState() {
    super.initState();
    // Hanya load jika belum ada cache
    if (context.read<MerchantBloc>().state is! FeaturedLoaded) {
      context.read<MerchantBloc>().add(LoadFeatured());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MerchantBloc, MerchantState>(
      listener: (context, state) {
        if (state is FeaturedLoaded) {
          setState(() => _cachedMerchants = state.merchants);
        }
      },
      builder: (context, state) {
        if (_cachedMerchants.isEmpty && state is MerchantLoading) {
          return _buildShimmer();
        }
        final merchants = _cachedMerchants.isNotEmpty
            ? _cachedMerchants
            : (state is FeaturedLoaded ? state.merchants : <MerchantModel>[]);
        if (merchants.isEmpty) return const SizedBox();

        // Ambil maks 7 merchant untuk row pertama (+ 1 slot "Lihat Semua")
        final displayed = merchants.take(7).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // ── Section Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Layanan Digital',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                  GestureDetector(
                    onTap: () => _goToAllMerchants(context),
                    child: Text('Lihat Semua',
                      style: TextStyle(
                        color: const Color(0xFF1a56db),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Grid 4 kolom ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount:   4,
                mainAxisSpacing:  16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
                children: [
                  ...displayed.map((m) => _buildItem(context, m)),
                  _buildLihatSemua(context), // Slot terakhir = "Lihat Semua"
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, MerchantModel merchant) {
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
            width: 58, height: 58,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: merchant.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(merchant.logoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconFallback(merchant)),
                  )
                : _iconFallback(merchant),
          ),
          const SizedBox(height: 6),
          Text(merchant.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            )),
        ],
      ),
    );
  }

  Widget _buildLihatSemua(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToAllMerchants(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              //ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Center(
              child: Icon(Icons.grid_view_rounded,
                color: Color(0xFF1a56db), size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text('Lihat\nSemua',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF1a56db),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.3,
            )),
        ],
      ),
    );
  }

  Widget _iconFallback(MerchantModel m) {
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

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 120, height: 18),
              _shimmerBox(width: 70, height: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
            children: List.generate(8, (_) => Column(
              children: [
                _shimmerBox(width: 58, height: 58, radius: 14),
                const SizedBox(height: 6),
                _shimmerBox(width: 50, height: 10),
              ],
            )),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({double? width, double? height, double radius = 8}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _goToAllMerchants(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<MerchantBloc>(),
        child: const MerchantHomeScreen(),
      ),
    ));
  }
}