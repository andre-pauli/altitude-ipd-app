import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseConfigSupport {
  static FirebaseDatabase? _database;
  static bool _isInitialized = false;

  static Future<void> initializeSupportApp() async {
    if (_isInitialized) return;

    try {
      // Configuração do Firebase para o projeto de suporte
      await Firebase.initializeApp(
        name: 'support',
        options: const FirebaseOptions(
          apiKey: "AIzaSyC4N382ry1IzpSJflgSeABD8n43fhftMlo",
          appId: "1:772955553248:android:3685b9468680a69b837f85",
          messagingSenderId: "772955553248",
          projectId: "altitude-support-capp-app",
          databaseURL:
              "https://altitude-support-capp-app-default-rtdb.firebaseio.com",
          storageBucket: "altitude-support-capp-app.firebasestorage.app",
        ),
      );

      _database = FirebaseDatabase.instanceFor(app: Firebase.app('support'));
      _isInitialized = true;
    } catch (e) {
      print('Erro ao inicializar Firebase: $e');
      rethrow;
    }
  }

  static Future<FirebaseDatabase> getSupportDatabaseRef() async {
    if (!_isInitialized) {
      await initializeSupportApp();
    }
    return _database!;
  }

  static Future<bool> checkDatabaseInstance() async {
    try {
      if (!_isInitialized) {
        await initializeSupportApp();
      }
      return _database != null;
    } catch (e) {
      print('Erro ao verificar instância do banco: $e');
      return false;
    }
  }
}
