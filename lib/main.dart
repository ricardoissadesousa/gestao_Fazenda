import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_theme.dart';
import 'core/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/producao_provider.dart';
import 'providers/abastecimento_provider.dart';
import 'providers/folga_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);
  runApp(const GestaoFazendaApp());
}

class GestaoFazendaApp extends StatelessWidget {
  const GestaoFazendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => ProducaoProvider()),
        ChangeNotifierProvider(create: (_) => AbastecimentoProvider()),
        ChangeNotifierProvider(create: (_) => FolgaProvider()),
      ],
      child: MaterialApp(
        title: 'Gestão de Fazenda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRoutes.roleSelection,
        routes: AppRoutes.routes,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
