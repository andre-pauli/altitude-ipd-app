import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IpdHomeController {
  static final IpdHomeController _instance = IpdHomeController._internal();

  factory IpdHomeController() => _instance;

  IpdHomeController._internal() {
    startListeningToMessages();
  }

  static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  static const eventChannel =
      EventChannel("com.example.altitude_ipd_app/receive_channel");

  int andarAtual = 1;
  double? temperatura;
  int? capacidadeMaximaKg;
  int? capacidadePessoas;
  double? latitude;
  double? longitude;
  String? direcaoMovimentacao;
  List<String>? mensagens;
  String? nomeObra;
  String? codigoObra;
  Map<String, dynamic> andares = {
    "1": {"andar": "0", "descricao": "Andar inicial"},
  };

  Function()? onUpdate;
  Function()? onUpdateWeater;

  Future<void> sendMessageToNative(Map<String, dynamic> mensagem) async {
    try {
      final String jsonMessage = jsonEncode(mensagem);
      log('mensagem enviada: $jsonMessage');
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

  Future<void> enviarComandoBooleano(
      {required String acao, required bool estado}) async {
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
        if (dados.containsKey("andar_atual")) andarAtual = dados["andar_atual"]??0;
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

        if (dados.containsKey("mensagens")) {
          mensagens = List<String>.from(dados["mensagens"]);
        }

        if (dados.containsKey("nome_obra")) {
          nomeObra = dados["nome_obra"];
        }
        if (dados.containsKey("codigo_obra")){
          codigoObra = dados["codigo_obra"];
        }

        if (dados.containsKey("andares")) {
          andares = dados["andares"];
        }

        if (dados.containsKey("latitude")) {
          latitude = dados["latitude"];
        }
        if (dados.containsKey("longitude")) {
          longitude = dados["longitude"];
        }

        if (latitude != null && longitude != null) {
          onUpdateWeater?.call();
        }

        onUpdate?.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao processar a mensagem recebida: $e");
      }
    }
  }
}
