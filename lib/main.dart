import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/wallet/wallet_bloc.dart';
import 'blocs/transfer/transfer_bloc.dart';
import 'blocs/topup/topup_bloc.dart';
import 'blocs/payment/payment_bloc.dart';
import 'blocs/contact/contact_bloc.dart';
import 'blocs/merchant/merchant_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/transfer/transfer_screen.dart';
import 'screens/topup/topup_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/main/main_screen.dart';
import 'blocs/qr/qr_bloc.dart';

void main() {
  runApp(const KyPayApp());
}

class KyPayApp extends StatelessWidget {
  const KyPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(CheckAuthStatus()),
      child: MaterialApp(
        title: 'KyPay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1a56db)),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // Buat BLoC baru setiap kali user login
              // Ini fix masalah WalletBloc fetch dengan token NULL setelah logout
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => WalletBloc()),
                  BlocProvider(create: (_) => TransferBloc()),
                  BlocProvider(create: (_) => TopUpBloc()),
                  BlocProvider(create: (_) => PaymentBloc()),
                  BlocProvider(create: (_) => QrBloc()),
                  BlocProvider(create: (_) => ContactBloc()),
                  BlocProvider(create: (_) => MerchantBloc()),
                ],
                child: const _AuthenticatedApp(),
              );
            }
            // Tampilkan login screen kalau belum auth
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

// ── Navigator untuk user yang sudah login ──────────────────────────────────
class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/transfer':
            return MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<TransferBloc>(),
                child: const TransferScreen(),
              ),
            );
          case '/topup':
            return MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<TopUpBloc>(),
                child: const TopUpScreen(),
              ),
            );
          case '/payment':
            return MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PaymentBloc>(),
                child: const PaymentScreen(),
              ),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthBloc>(),
                child: const RegisterScreen(),
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const MainScreen(),
            );
        }
      },
    );
  }
}