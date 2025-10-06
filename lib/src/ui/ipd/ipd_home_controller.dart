import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../services/robust_websocket_service.dart';
// import 'package:flutter/services.dart';

class IpdHomeController {
  static final IpdHomeController _instance = IpdHomeController._internal();

  factory IpdHomeController() => _instance;

  IpdHomeController._internal() {
    _initWebSocket();
    if (_useWebSocket) {
      print('IPD Controller: 🔄 Conectando automaticamente ao WebSocket...');
      _webSocketService.connect();
    }
  }

  final RobustWebSocketService _webSocketService = RobustWebSocketService();
  bool _useWebSocket = true;

  bool get useWebSocket => _useWebSocket;
  bool get isWebSocketConnected => _webSocketService.isConnected;
  RobustWebSocketService get webSocketService => _webSocketService;

  void setUseWebSocket(bool use) {
    _useWebSocket = use;
    if (use) {
      print('IPD Controller: 🌐 Ativando modo WebSocket');
      _webSocketService.connect();
    } else {
      print('IPD Controller: 📡 Desativando modo WebSocket');
      _webSocketService.disconnect();
    }
  }

  void _initWebSocket() {
    print('IPD Controller: 🔧 Inicializando WebSocket robusto...');

    _webSocketService.onDataReceived = (data) {
      print('IPD Controller: 📨 Dados recebidos via WebSocket');
      _processarMensagemRecebida(jsonEncode(data));
    };

    _webSocketService.onConnected = () {
      print('IPD Controller: ✅ WebSocket conectado com sucesso');
      onUpdate?.call();
    };

    _webSocketService.onDisconnected = () {
      print('IPD Controller: 🔌 WebSocket desconectado');
      onUpdate?.call();
    };

    _webSocketService.onError = (error) {
      print('IPD Controller: ❌ Erro no WebSocket: $error');
    };
  }

  // static const platform = MethodChannel("com.example.altitude_ipd_app/channel");
  // static const eventChannel =
  //     EventChannel("com.example.altitude_ipd_app/receive_channel");

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
  Map<String, dynamic> andares = {};
  String? dataUltimaManutencao;

  Function()? onUpdate;
  Function()? onUpdateWeater;

  Future<void> sendMessageToNative(Map<String, dynamic> mensagem) async {
    try {
      final String jsonMessage = jsonEncode(mensagem);
      log('mensagem enviada: $jsonMessage');

      if (_useWebSocket && _webSocketService.isConnected) {
        // Usar WebSocket se estiver ativado e conectado
        _webSocketService.sendMessage(mensagem);
      } else {
        // Usar RS485 (simulado no Linux)
        // await platform.invokeMethod('sendMessage', jsonMessage);
        print("Linux mode: Mensagem simulada - $jsonMessage");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao enviar mensagem: ${e.toString()}");
      }
    }
  }

  Future<void> enviarComandoIrParaAndar(int andarDestino) async {
    if (_useWebSocket && _webSocketService.isConnected) {
      await _webSocketService.sendGoToFloor(andarDestino);
    } else {
      final Map<String, dynamic> mensagem = {
        "tipo": "comando",
        "acao": "ir_para_andar",
        "andar_destino": andarDestino,
        "dados": null,
        "timestamp": DateTime.now().toIso8601String(),
      };
      await sendMessageToNative(mensagem);
    }

    // Simular mudança de andar no Linux
    andarAtual = andarDestino;
    onUpdate?.call();
  }

  Future<void> enviarComandoBooleano(
      {required String acao, required bool estado}) async {
    if (_useWebSocket && _webSocketService.isConnected) {
      await _webSocketService.sendBooleanCommand(
        action: acao,
        estado: estado,
      );
    } else {
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
  }

  Future<void> requestInitialData() async {
    if (_useWebSocket && _webSocketService.isConnected) {
      await _webSocketService.requestInitialData();
    }
  }

  Future<bool> waitForWebSocketConnection({int maxWaitSeconds = 10}) async {
    if (!_useWebSocket) return false;
    
    final maxWaitMs = maxWaitSeconds * 1000;
    final checkInterval = 500; // 500ms
    int waited = 0;
    
    while (waited < maxWaitMs) {
      if (_webSocketService.isConnected) {
        final stats = _webSocketService.getConnectionStats();
        final isHealthy = stats['isConnectionHealthy'] as bool;
        
        if (isHealthy) {
          print('✅ WebSocket está conectado e saudável');
          return true;
        }
      }
      
      await Future.delayed(Duration(milliseconds: checkInterval));
      waited += checkInterval;
    }
    
    print('⚠️ Timeout aguardando conexão WebSocket');
    return false;
  }

  // void startListeningToMessages() {
  //   eventChannel.receiveBroadcastStream().listen((message) {
  //     final txt = message as String;
  //     _processarMensagemRecebida(txt);
  //   }, onError: (error) {
  //     if (kDebugMode) {
  //       print("Erro ao receber mensagem do Android: $error");
  //     }
  //   });
  // }

  void _processarMensagemRecebida(String message) {
    print('Mensagem recebida: $message');
    try {
      final Map<String, dynamic> decodedMessage = jsonDecode(message);
      final String? tipo = decodedMessage["tipo"];
      final Map<String, dynamic>? dados = decodedMessage["dados"];

      if (tipo == "status" && dados != null) {
        if (dados.containsKey("andar_atual")) {
          andarAtual = dados["andar_atual"];
        }
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
        if (dados.containsKey("codigo_obra")) {
          codigoObra = dados["codigo_obra"];
        }

        if (dados.containsKey("andares")) {
          if (andares.isEmpty) {
            andares = dados["andares"];
          }
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
        if (dados.containsKey("data_ultima_manutencao")) {
          dataUltimaManutencao = dados["data_ultima_manutencao"];
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
