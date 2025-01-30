import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

late FirebaseApp supportApp;

Future<void> initializeSupportApp() async {
  supportApp = await Firebase.initializeApp(
    name: 'SupportApp',
    options: FirebaseOptions(
      apiKey: "AIzaSyC4N382ry1IzpSJflgSeABD8n43fhftMlo",
      databaseURL:
          "https://altitude-support-capp-app-default-rtdb.firebaseio.com",
      projectId: "altitude-support-capp-app",
      storageBucket: "altitude-support-capp-app.firebasestorage.app",
      messagingSenderId: "772955553248",
      appId: "1:772955553248:android:3685b9468680a69b837f85",
    ),
  );
}

Future<FirebaseDatabase> getSupportDatabaseRef() async {
  return FirebaseDatabase.instanceFor(app: supportApp);
}
