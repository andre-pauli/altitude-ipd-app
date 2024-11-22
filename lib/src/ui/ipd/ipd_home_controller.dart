import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IpdHomeController {
  static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  static const eventChannel =
      EventChannel("com.example.altitude_ipd_app/receive_channel");

  int? andarAtual;
  double? temperatura;
  double? capacidadeMaximaKg;
  int? capacidadePessoas;
  String? direcaoMovimentacao;
  List<String>? mensagens;
  String? nomeObra;
  String? codigoObra;

  Function()? onUpdate;

  IpdHomeController({this.onUpdate}) {
    startListeningToMessages();
  }

  Future<void> sendMessageToNative(Map<String, dynamic> mensagem) async {
    try {
      final String jsonMessage = jsonEncode(mensagem);
      await platform.invokeMethod('sendMessage', jsonMessage);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Erro ao enviar mensagem para o Android: ${e.message}");
      }
    }
  }

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
      if (kDebugMode) {
        print("Erro ao receber mensagem do Android: $error");
      }
    });
  }

  void _processarMensagemRecebida(String message) {
    print('Mensagem recebida: $message');
    try {
      final Map<String, dynamic> decodedMessage = jsonDecode(message);
      final String? tipo = decodedMessage["tipo"];
      final Map<String, dynamic>? dados = decodedMessage["dados"];

      if (tipo == "status" && dados != null) {
        if (dados.containsKey("andar_atual")) andarAtual = dados["andar_atual"];
        if (dados.containsKey("temperatura")) {
          temperatura = (dados["temperatura"] as num).toDouble();
        }
        if (dados.containsKey("capacidade_maxima_kg")) {
          capacidadeMaximaKg = dados["capacidade_maxima_kg"];
        }
        if (dados.containsKey("capacidade_pessoas")) {
          capacidadePessoas = dados["capacidade_pessoas"];
        }
        direcaoMovimentacao = dados["direcao_movimentacao"];
        mensagens = dados.containsKey("mensagens")
            ? List<String>.from(dados["mensagens"])
            : null;
        nomeObra = dados["nome_obra"];
        codigoObra = dados["codigo_obra"];

        onUpdate?.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao processar a mensagem recebida: $e");
      }
    }
  }
}
