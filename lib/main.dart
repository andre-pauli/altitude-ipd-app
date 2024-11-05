import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  static const eventChannel =
      EventChannel("com.example.altitude_ipd_app/receive_channel");

  String _receivedMessage = "Nada Recebido";

  @override
  void initState() {
    super.initState();
    startListeningToMessages();
  }

  Future<void> sendMessageToNative(String message) async {
    try {
      final String response =
          await platform.invokeMethod('sendMessage', message);
      print("Resposta do Android: $response");
    } on PlatformException catch (e) {
      print("Erro ao enviar mensagem para o Android: ${e.message}");
    }
  }

  void startListeningToMessages() {
    eventChannel.receiveBroadcastStream().listen((message) {
      setState(() {
        _receivedMessage = message; // Atualiza o texto recebido em tempo real
      });
      print("Mensagem recebida do Android: $message");
    }, onError: (error) {
      print("Erro ao receber mensagem do Android: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Flutter RS485 Comunicação"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Mensagem Recebida: $_receivedMessage"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    sendMessageToNative("Mensagem de teste para RS485"),
                child: Text("Enviar Mensagem para RS485"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
