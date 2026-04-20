import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
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
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar + Info ──────────────────────────────────
              Center(
                child: Column(
                  children: [
                    _buildAvatar(user?.avatarUrl, user?.name ?? ''),
                    const SizedBox(height: 12),
                    Text(user?.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Menu items ─────────────────────────────────────
              _buildMenuItem(
                icon:  Icons.person_outline,
                label: 'Edit Profil',
                subtitle: 'Ubah nama, nomor HP, bio, dan pekerjaan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: const EditProfileScreen(),
                    ),
                  ),
                ),
              ),
              _buildMenuItem(
                icon:  Icons.lock_outline,
                label: 'Ubah Password',
                subtitle: 'Perbarui password akun kamu',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              _buildMenuItem(
                icon:  Icons.help_outline,
                label: 'Bantuan',
                subtitle: 'FAQ dan informasi kontak support',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HelpScreen()),
                ),
              ),

              const SizedBox(height: 16),

              // ── Logout ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  //ignore: deprecated_member_use
                      Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Keluar',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600)),
                  onTap: () =>
                      context.read<AuthBloc>().add(LogoutRequested()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: const Color(0xFF1a56db).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: const Color(0xFF1a56db), size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(
              //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.4),
                fontSize: 12)),
        trailing: Icon(Icons.chevron_right,
        //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'K';
    final fallback = CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1a56db),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold),
      ),
    );

    if (avatarUrl == null || avatarUrl.isEmpty) return fallback;

    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF1a56db),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }
}