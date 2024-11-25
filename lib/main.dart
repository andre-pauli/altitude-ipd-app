import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startKioskMode();
  runApp(const AltitudeIpdApp());
}

class AltitudeIpdApp extends StatelessWidget {
  const AltitudeIpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'Altitude IPD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const IpdHomePage(),
    );
  }
}
