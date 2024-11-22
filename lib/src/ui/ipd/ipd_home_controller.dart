import 'dart:convert';
import 'package:flutter/services.dart';

class IpdHomeController {
  static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  static const eventChannel =
      EventChannel("com.example.altitude_ipd_app/receive_channel");

  // Variáveis para armazenar os dados recebidos
  int? andarAtual;
  double? temperatura;
  int? capacidadeMaximaKg;
  String? direcaoMovimentacao;
  List<String>? mensagens;
  String? nomeObra;
  String? codigoObra;

  // Listener de atualizações
  Function()? onUpdate;

  IpdHomeController({this.onUpdate}) {
    startListeningToMessages();
  }

  // Envia uma mensagem usando MethodChannel
  Future<void> sendMessageToNative(Map<String, dynamic> mensagem) async {
    try {
      final String jsonMessage = jsonEncode(mensagem);
      await platform.invokeMethod('sendMessage', jsonMessage);
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
        // Atualiza apenas os campos presentes na mensagem recebida
        if (dados.containsKey("andar_atual")) andarAtual = dados["andar_atual"];
        if (dados.containsKey("temperatura"))
          temperatura = (dados["temperatura"] as num).toDouble();
        if (dados.containsKey("capacidade_maxima_kg"))
          capacidadeMaximaKg = dados["capacidade_maxima_kg"];
        direcaoMovimentacao = dados["direcao_movimentacao"];
        mensagens = dados.containsKey("mensagens")
            ? List<String>.from(dados["mensagens"])
            : null;
        nomeObra = dados["nome_obra"];
        codigoObra = dados["codigo_obra"];

        // Notifica listeners sobre a atualização
        onUpdate?.call();
      }
    } catch (e) {
      print("Erro ao processar a mensagem recebida: $e");
    }
  }
}
