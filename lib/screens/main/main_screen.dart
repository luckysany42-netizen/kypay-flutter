import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../wallet/wallet_screen.dart';
import '../qr/qr_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../contact/contact_screen.dart';
import '../../blocs/qr/qr_bloc.dart';
import '../../blocs/qr/qr_event.dart';
import '../../blocs/contact/contact_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WalletScreen(openHistoryTab: () => _onTabTapped(1)),
      const HistoryScreen(),
      const SizedBox(), // QR (tidak dipakai langsung)
      // ✅ ContactScreen dibungkus BlocProvider.value agar pakai
      // ContactBloc yang sama dari MultiBlocProvider di main.dart
      BlocProvider.value(
        value: context.read<ContactBloc>()..add(FetchContacts()),
        child: const ContactScreen(),
      ),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // ✅ QR fullscreen modal (seperti GoPay)
      context.read<QrBloc>().add(ResetQr());
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => BlocProvider.value(
            value: context.read<QrBloc>(),
            child: const QrScreen(),
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0d1829),
        border: Border(
          //ignore: deprecated_member_use
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            //ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Beranda
              _buildNavItem(
                0,
                Icons.home_rounded,
                Icons.home_outlined,
                'Beranda',
              ),

              // Riwayat
              _buildNavItem(
                1,
                Icons.receipt_long_rounded,
                Icons.receipt_long_outlined,
                'Riwayat',
              ),

              // 🔥 QR tombol tengah (floating style)
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1a56db),
                              Color(0xFF3b82f6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              //ignore: deprecated_member_use
                              color: const Color(0xFF1a56db).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Kontak
              _buildNavItem(
                3,
                Icons.people_rounded,
                Icons.people_outline_rounded,
                'Kontak',
              ),

              // Profil
              _buildNavItem(
                4,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive
                  ? const Color(0xFF1a56db)
                  //ignore: deprecated_member_use
                  : Colors.white.withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF1a56db)
                    // ignore: deprecated_member_use
                    : Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}