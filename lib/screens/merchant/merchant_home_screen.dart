import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/merchant/merchant_bloc.dart';
import '../../blocs/merchant/merchant_event.dart';
import '../../blocs/merchant/merchant_state.dart';
import '../../models/merchant_model.dart';
import '../../models/merchant_category_model.dart';
import 'merchant_list_screen.dart';
import 'merchant_input_screen.dart';

/// Halaman "Semua Layanan Digital" — mirip GoPay "Semua Fitur"
/// Berisi: search bar + filter kategori + grid merchant per kategori
class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryCode;
  bool    _isSearching = false;

  // Cache data supaya tidak reload saat ganti filter
  List<MerchantCategoryModel> _categories = [];
  List<MerchantModel>         _allMerchants = [];

  @override
  void initState() {
    super.initState();
    context.read<MerchantBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Layanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: BlocListener<MerchantBloc, MerchantState>(
        listener: (context, state) {
          if (state is CategoriesLoaded) {
            setState(() => _categories = state.categories);
            // Setelah kategori loaded, load semua merchant
            context.read<MerchantBloc>().add(LoadMerchants());
          } else if (state is MerchantsLoaded) {
            setState(() => _allMerchants = state.merchants);
          }
        },
        child: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  setState(() => _isSearching = val.isNotEmpty);
                  if (val.length >= 2) {
                    context.read<MerchantBloc>().add(SearchMerchants(val));
                  } else if (val.isEmpty) {
                    context.read<MerchantBloc>().add(LoadMerchants(
                      categoryCode: _selectedCategoryCode,
                    ));
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Cari layanan...',
                  //ignore: deprecated_member_use
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  //ignore: deprecated_member_use
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search,
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.4)),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: Icon(Icons.clear,
                            //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.4)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _isSearching = false);
                            context.read<MerchantBloc>().add(LoadMerchants(
                              categoryCode: _selectedCategoryCode,
                            ));
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Filter Kategori ─────────────────────────────────────────────
            if (_categories.isNotEmpty && !_isSearching)
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _buildFilterChip(
                        label: 'Semua',
                        selected: _selectedCategoryCode == null,
                        onTap: () {
                          setState(() => _selectedCategoryCode = null);
                          context.read<MerchantBloc>().add(LoadMerchants());
                        },
                      );
                    }
                    final cat = _categories[i - 1];
                    return _buildFilterChip(
                      label: cat.name,
                      selected: _selectedCategoryCode == cat.code,
                      color: _parseColor(cat.colorHex),
                      onTap: () {
                        setState(() => _selectedCategoryCode = cat.code);
                        context.read<MerchantBloc>().add(LoadMerchants(
                          categoryCode: cat.code,
                        ));
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<MerchantBloc, MerchantState>(
                builder: (context, state) {
                  if (state is MerchantLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1a56db)),
                    );
                  }

                  if (state is MerchantError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                            //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.3), size: 48),
                          const SizedBox(height: 12),
                          Text(state.message,
                            //ignore: deprecated_member_use
                            style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    );
                  }

                  final merchants = _allMerchants;
                  if (merchants.isEmpty) {
                    return Center(
                      child: Text('Tidak ada layanan ditemukan.',
                        //ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.4))),
                    );
                  }

                  // Jika ada filter kategori atau search → tampilkan flat grid
                  if (_selectedCategoryCode != null || _isSearching) {
                    return _buildFlatGrid(merchants);
                  }

                  // Tampilkan per kategori
                  return _buildGroupedByCategory(merchants);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid flat (saat filter/search aktif) ───────────────────────────────────
  Widget _buildFlatGrid(List<MerchantModel> merchants) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   4,
        mainAxisSpacing:  16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: merchants.length,
      itemBuilder: (_, i) => _buildMerchantItem(merchants[i]),
    );
  }

  // ── Grid grouped per kategori ──────────────────────────────────────────────
  Widget _buildGroupedByCategory(List<MerchantModel> merchants) {
    // Group merchants by category
    final Map<String, List<MerchantModel>> grouped = {};
    for (final m in merchants) {
      final key = m.category?.name ?? 'Lainnya';
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final categoryName = grouped.keys.elementAt(i);
        final items        = grouped[categoryName]!;
        final cat = _categories.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => MerchantCategoryModel(
            id: 0, 
            code: '', 
            name: categoryName, 
            colorHex: '#1a56db',
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header kategori
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          color: _parseColor(cat.colorHex),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        )),
                    ],
                  ),
                  if (items.length > 4)
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<MerchantBloc>(),
                          child: MerchantListScreen(
                            categoryCode: cat.code,
                            categoryName: categoryName,
                          ),
                        ),
                      )),
                      child: Text('Lihat semua',
                        style: TextStyle(
                          color: _parseColor(cat.colorHex),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                ],
              ),
            ),

            // Grid merchant (maks 8 per kategori)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount:   4,
                mainAxisSpacing:  16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: items.take(8).map(_buildMerchantItem).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Merchant item ──────────────────────────────────────────────────────────
  Widget _buildMerchantItem(MerchantModel merchant) {
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
            width: 60, height: 60,
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.06)),
            ),
            child: merchant.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      merchant.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _merchantIconFallback(merchant),
                    ),
                  )
                : _merchantIconFallback(merchant),
          ),
          const SizedBox(height: 6),
          Text(
            merchant.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _merchantIconFallback(MerchantModel merchant) {
    final color = merchant.category != null
        ? _parseColor(merchant.category!.colorHex)
        : const Color(0xFF1a56db);
    final emoji = switch (merchant.category?.code ?? '') {
      'game'    => '🎮',
      'pulsa'   => '📱',
      'tagihan' => '📄',
      'rumah'   => '⚡',
      'hiburan' => '🎵',
      _         => '💳',
    };
    return Container(
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool   selected,
    Color?          color,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? const Color(0xFF1a56db);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              //ignore: deprecated_member_use
              ? activeColor.withOpacity(0.2)
              //ignore: deprecated_member_use
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            //ignore: deprecated_member_use
            color: selected ? activeColor : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : Colors.white.withOpacity(0.6),//ignore: deprecated_member_use
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF1a56db);
    }
  }
}