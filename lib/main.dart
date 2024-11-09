import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  static const eventChannel = EventChannel("com.example.altitude_ipd_app/receive_channel");

  String _receivedMessage = "Nada Recebido";

  // Variáveis para armazenar os dados recebidos
  int? _andarAtual;
  double? _temperatura;
  int? _capacidadeMaximaKg;
  String? _direcaoMovimentacao;
  List<String>? _mensagens;
  String? _nomeObra;
  String? _codigoObra;

  @override
  void initState() {
    super.initState();
    startListeningToMessages();
  }

  // Envia uma mensagem usando MethodChannel
  Future<void> sendMessageToNative(Map<String, dynamic> mensagem) async {
    try {
      final String jsonMessage = jsonEncode(mensagem);
      final String response = await platform.invokeMethod('sendMessage', jsonMessage);
      print("Resposta do Android: $response");
    } on PlatformException catch (e) {
      print("Erro ao enviar mensagem para o Android: ${e.message}");
    }
  }

  // Métodos de envio específicos
  Future<void> enviarComandoIrParaAndar(int andarDestino) async {
    final Map<String, dynamic> mensagem = {
      "tipo": "comando",
      "acao": "ir_para_andar",
      "andar_destino": andarDestino,
      "dados": null,
      "timestamp": DateTime.now().toIso8601String(),
    };
    await sendMessageToNative(mensagem);
  }

  Future<void> enviarComandoBooleano(String acao, bool estado) async {
    final Map<String, dynamic> mensagem = {
      "tipo": "comando",
      "acao": acao,
      "andar_destino": null,
      "dados": {
        "estado": estado,
      },
      "timestamp": DateTime.now().toIso8601String(),
    };
    await sendMessageToNative(mensagem);
  }

  void startListeningToMessages() {
    eventChannel.receiveBroadcastStream().listen((message) {
      final txt = message as String;
      _processarMensagemRecebida(txt);
    }, onError: (error) {
      print("Erro ao receber mensagem do Android: $error");
    });
  }

  void _processarMensagemRecebida(String message) {
    try {
      final Map<String, dynamic> decodedMessage = jsonDecode(message);
      final String? tipo = decodedMessage["tipo"];
      final Map<String, dynamic>? dados = decodedMessage["dados"];

      if (tipo == "status" && dados != null) {
        setState(() {
          // Atualiza apenas os campos presentes na mensagem recebida
          if (dados.containsKey("andar_atual")) _andarAtual = dados["andar_atual"];
          if (dados.containsKey("temperatura")) _temperatura = (dados["temperatura"] as num).toDouble();
          if (dados.containsKey("capacidade_maxima_kg")) _capacidadeMaximaKg = dados["capacidade_maxima_kg"];
          dados.containsKey("direcao_movimentacao")? _direcaoMovimentacao = dados["direcao_movimentacao"] : _direcaoMovimentacao = null;
          dados.containsKey("mensagens")? _mensagens = List<String>.from(dados["mensagens"]) : _mensagens = null;
          if (dados.containsKey("nome_obra")) _nomeObra = dados["nome_obra"];
          if (dados.containsKey("codigo_obra")) _codigoObra = dados["codigo_obra"];
        });
      }
    } catch (e) {
      print("Erro ao processar a mensagem recebida: $e");
    }
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
              const SizedBox(height: 20),
              _buildStatusWidget(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => enviarComandoIrParaAndar(1),
                child: Text("Enviar Comando: Ir para o Andar 1"),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () => enviarComandoIrParaAndar(2),
                child: Text("Enviar Comando: Ir para o Andar 2"),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () => enviarComandoIrParaAndar(3),
                child: Text("Enviar Comando: Ir para o Andar 3"),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () => enviarComandoIrParaAndar(4),
                child: Text("Enviar Comando: Ir para o Andar 4"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_andarAtual != null) Text("Andar Atual: $_andarAtual"),
        if (_temperatura != null) Text("Temperatura: $_temperatura°C"),
        if (_capacidadeMaximaKg != null) Text("Capacidade Máxima (kg): $_capacidadeMaximaKg"),
        if (_direcaoMovimentacao != null) Text("Direção de Movimentação: $_direcaoMovimentacao"),
        if (_mensagens != null) Text("Mensagens: ${_mensagens!.join(', ')}"),
        if (_nomeObra != null) Text("Nome da Obra: $_nomeObra"),
        if (_codigoObra != null) Text("Código da Obra: $_codigoObra"),
      ],
    );
  }
}
