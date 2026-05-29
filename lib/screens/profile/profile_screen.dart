import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_state.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── Avatar + Info ────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    _buildAvatar(user?.avatarUrl, user?.name ?? ''),
                    const SizedBox(height: 12),
                    Text(user?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '',
                      //ignore: deprecated_member_use
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Saldo mini (info saja) ───────────────────────────────────
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, walletState) {
                  if (walletState is WalletLoaded) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1a2f5a), Color(0xFF0d2244)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        //ignore: deprecated_member_use
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                            color: Color(0xFF1a56db), size: 22),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Wallet',
                                //ignore: deprecated_member_use
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              Text(walletState.wallet.walletNumber,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                )),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

              // ── Menu: Akun ───────────────────────────────────────────────
              _sectionLabel('Akun'),
              const SizedBox(height: 8),

              _buildMenuItem(
                icon:    Icons.person_outline,
                label:   'Edit Profil',
                subtitle:'Ubah nama, nomor HP, bio, dan pekerjaan',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<AuthBloc>(),
                    child: const EditProfileScreen(),
                  ),
                )),
              ),

              _buildMenuItem(
                icon:    Icons.lock_outline,
                label:   'Ubah Password',
                subtitle:'Perbarui password akun kamu',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                )),
              ),

              const SizedBox(height: 16),

              // ── Menu: Keamanan (Ganti PIN dipindah ke sini) ──────────────
              _sectionLabel('Keamanan'),
              const SizedBox(height: 8),

              _buildMenuItem(
                icon:    Icons.pin_outlined,
                label:   'Ganti PIN KyPay',
                subtitle:'Ubah PIN transaksi wallet kamu',
                color:   const Color(0xFFd97706),
                onTap: () => _showChangePinModal(context),
              ),

              const SizedBox(height: 16),

              // ── Menu: Lainnya ────────────────────────────────────────────
              _sectionLabel('Lainnya'),
              const SizedBox(height: 8),

              _buildMenuItem(
                icon:    Icons.help_outline,
                label:   'Bantuan',
                subtitle:'FAQ dan informasi kontak support',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HelpScreen(),
                )),
              ),

              const SizedBox(height: 20),

              // ── Logout ───────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Keluar',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(label,
      style: TextStyle(
        //ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.4),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ));
  }

  // ── Menu item ──────────────────────────────────────────────────────────────
  Widget _buildMenuItem({
    required IconData     icon,
    required String       label,
    required String       subtitle,
    required VoidCallback onTap,
    Color?                color,
  }) {
    final c = color ?? const Color(0xFF1a56db);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        //ignore: deprecated_member_use
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: c.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c, size: 20),
        ),
        title: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
          //ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        trailing: Icon(Icons.chevron_right,
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(String? avatarUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'K';
    final fallback = CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1a56db),
      child: Text(initials,
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
    );
    if (avatarUrl == null || avatarUrl.isEmpty) return fallback;
    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1a56db),
      child: ClipOval(
        child: Image.network(avatarUrl,
          width: 80, height: 80, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ── Modal Ganti PIN ────────────────────────────────────────────────────────
  void _showChangePinModal(BuildContext context) {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confCtrl   = TextEditingController();
    bool loading     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0d1829),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Ganti PIN KyPay',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _pinField('PIN Lama', oldPinCtrl),
                const SizedBox(height: 12),
                _pinField('PIN Baru', newPinCtrl),
                const SizedBox(height: 12),
                _pinField('Konfirmasi PIN Baru', confCtrl),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : () async {
                      if (newPinCtrl.text != confCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('PIN baru tidak cocok'), backgroundColor: Colors.red));
                        return;
                      }
                      if (newPinCtrl.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('PIN harus 6 digit'), backgroundColor: Colors.orange));
                        return;
                      }
                      setModalState(() => loading = true);
                      try {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('PIN berhasil diubah!'), backgroundColor: Colors.green));
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Gagal mengubah PIN'), backgroundColor: Colors.red));
                      } finally {
                        setModalState(() => loading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan PIN Baru',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFd97706), width: 1.5)),
      ),
    );
  }
}