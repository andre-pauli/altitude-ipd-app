import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startKioskMode();
  runApp(const AltitudeIpdApp());
}

class AltitudeIpdApp extends StatefulWidget {
  const AltitudeIpdApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const IpdHomePage(),
    );
  }
}
