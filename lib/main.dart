import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kasir_pro/providers/user_profile_provider.dart'; // ✅ Tambahkan provider
import 'package:kasir_pro/screens/home/administrasi_screen.dart';
import 'package:provider/provider.dart'; // ✅ Tambahkan Provider

import 'firebase_options.dart';
import 'screens/forgot_password1.dart';
import 'screens/forgot_password2.dart';
import 'screens/forgot_password3.dart';
import 'screens/home/catatanbelanja_screen.dart';
import 'screens/home/daftarpesanan_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/katalogmenu_screen.dart';
import 'screens/home/pemesanan_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  runApp(const KasirProApp());
}

class KasirProApp extends StatelessWidget {
  const KasirProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ✅ WRAP DENGAN MULTIPROVIDER
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        // Tambahkan provider lain di sini jika diperlukan
      ],
      child: MaterialApp(
        title: 'KasirPro',
        debugShowCheckedModeBanner: false,

        // ✅ Localization settings agar DatePicker & format tanggal berbahasa Indonesia
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        theme: ThemeData(
          primaryColor: const Color(0xFF2196F3),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),

        initialRoute: '/login',

        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password1': (context) => const ForgotPassword1(),
          '/home': (context) => const DashboardScreen(),
          '/administrasi': (context) => const AdministrasiScreen(),
          '/pemesanan': (context) => const PemesananScreen(),
          '/daftar_pesanan': (context) => const DaftarPesananScreen(),
          '/katalog_menu': (context) => const KatalogMenuScreen(),
          '/profil': (context) => const ProfilScreen(),
          '/catatan_belanja': (context) => const CatatanBelanjaScreen(),
        },

        // ✅ Route dinamis
        onGenerateRoute: (settings) {
          if (settings.name == '/forgot_password2') {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ForgotPassword2Screen(email: email),
            );
          }

          if (settings.name == '/forgot_password3') {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ForgotPassword3Screen(email: email),
            );
          }

          return null;
        },
      ),
    );
  }
}
