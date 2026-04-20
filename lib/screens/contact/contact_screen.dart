import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/contact/contact_bloc.dart';

class ContactScreen extends StatefulWidget {
  /// Jika [isSelector] = true (dipanggil dari Transfer),
  /// klik kontak langsung return wallet_number via Navigator.pop
  final bool isSelector;
  const ContactScreen({super.key, this.isSelector = false});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ContactBloc>().add(FetchContacts());
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
        title: const Text('Kontak',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        // Tombol back hanya muncul kalau dipanggil dari Transfer
        leading: widget.isSelector
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              _searchController.clear();
              context.read<ContactBloc>().add(FetchContacts());
            },
          ),
        ],
      ),
      body: BlocBuilder<ContactBloc, ContactState>(
        builder: (context, state) {
          if (state is ContactLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0891b2)),
            );
          }

          if (state is ContactError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ContactBloc>().add(FetchContacts()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891b2)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is ContactLoaded) {
            return _buildLoaded(state);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoaded(ContactLoaded state) {
    final favorites = state.favorites;
    final contacts  = state.filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (q) =>
                context.read<ContactBloc>().add(SearchContacts(q)),
            decoration: InputDecoration(
              hintText: 'Cari nama atau nomor wallet...',
              hintStyle:
              // ignore: deprecated_member_use
                  TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white54, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<ContactBloc>()
                            .add(const SearchContacts(''));
                      },
                    )
                  : null,
              filled: true,
              //ignore: deprecated_member_use
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF0891b2), width: 1.5),
              ),
            ),
          ),
        ),

        // ── Kosong ────────────────────────────────────────
        if (contacts.isEmpty && state.all.isEmpty) ...[
          Expanded(child: _buildEmpty()),
        ] else ...[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // ── Favorit ─────────────────────────────
                if (favorites.isNotEmpty &&
                    state.query.isEmpty) ...[
                  _sectionTitle('⭐  Favorit'),
                  SizedBox(
                    height: 96,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16),
                      itemCount: favorites.length,
                      itemBuilder: (_, i) =>
                          _favoriteChip(favorites[i]),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Semua Kontak ─────────────────────────
                _sectionTitle(state.query.isEmpty
                    ? 'Semua Kontak  (${contacts.length})'
                    : 'Hasil Pencarian  (${contacts.length})'),

                if (contacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Tidak ada kontak yang cocok.',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
                  )
                else
                  ...contacts
                      .map((c) => _contactTile(c))
                      // ignore: unnecessary_to_list_in_spreads
                      .toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Empty state ──────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
          //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.2), size: 72),
          const SizedBox(height: 16),
          Text('Belum ada kontak',
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Kontak akan muncul otomatis\nsetelah kamu pernah transfer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Section title ────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Favorit horizontal chip ──────────────────────────────
  Widget _favoriteChip(ContactModel c) {
    return GestureDetector(
      onTap: () => _onContactTap(c),
      child: Container(
        margin: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
        child: Column(
          children: [
            _avatar(c, radius: 26),
            const SizedBox(height: 5),
            SizedBox(
              width: 56,
              child: Text(
                c.ownerName.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact tile ─────────────────────────────────────────
  Widget _contactTile(ContactModel c) {
    return GestureDetector(
      onTap: () => _onContactTap(c),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          //ignore: deprecated_member_use
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            _avatar(c, radius: 22),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.ownerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(c.walletNumber,
                      style: TextStyle(
                        //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12)),
                ],
              ),
            ),

            // Tombol favorit
            GestureDetector(
              onTap: () => context
                  .read<ContactBloc>()
                  .add(ToggleFavorite(c.walletNumber)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Icon(
                  c.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: c.isFavorite
                      ? const Color(0xFFf59e0b)
                      : Colors.white24,
                  size: 22,
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 13),
          ],
        ),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────
  Widget _avatar(ContactModel c, {double radius = 22}) {
    if (c.ownerAvatar != null && c.ownerAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(c.ownerAvatar!),
        backgroundColor: const Color(0xFF0891b2),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0891b2),
      child: Text(
        c.ownerName.isNotEmpty ? c.ownerName[0].toUpperCase() : '?',
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8),
      ),
    );
  }

  // ── Tap handler ──────────────────────────────────────────
  void _onContactTap(ContactModel c) {
    if (widget.isSelector) {
      // Dipanggil dari Transfer → return wallet_number
      Navigator.pop(context, c.walletNumber);
    }
    // Kalau dari navbar → tidak ada aksi khusus
    // (bisa ditambah detail kontak di masa depan)
  }
}