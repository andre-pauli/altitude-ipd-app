import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    print('=== INICIANDO ALTITUDE IPD APP ===');

    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding inicializado');

    await Firebase.initializeApp();
    print('Firebase inicializado');

    await loginAnonymously();
    print('Login anônimo realizado');

    print('=== ALTITUDE IPD APP INICIADO COM SUCESSO ===');
    runApp(const AltitudeIpdApp());
  } catch (e) {
    print('ERRO ao inicializar app: $e');
    rethrow;
  }
}

Future<User?> loginAnonymously() async {
  try {
    print('Iniciando login anônimo...');
    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    print(
        'Login anônimo realizado com sucesso - UID: ${userCredential.user?.uid}');
    return userCredential.user;
  } catch (e) {
    print("ERRO no login anônimo: $e");
    return null;
  }
}

class AltitudeIpdApp extends StatefulWidget {
  const AltitudeIpdApp({super.key});

  @override
  _AltitudeIpdAppState createState() => _AltitudeIpdAppState();
}

class _AltitudeIpdAppState extends State<AltitudeIpdApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altitude IPD',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const IpdHomePage(),
    );
  }
}
