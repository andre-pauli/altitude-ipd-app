import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../services/websocket_service.dart';
// import 'package:flutter/services.dart';

class IpdHomeController {
  static final IpdHomeController _instance = IpdHomeController._internal();

  factory IpdHomeController() => _instance;

  IpdHomeController._internal() {
    _initWebSocket();
    // startListeningToMessages();
    // Simular dados para Linux
    _simulateData();

    // Conecta automaticamente ao WebSocket após um pequeno delay
    Future.delayed(Duration(seconds: 2), () {
      if (_useWebSocket) {
        print('IPD Controller: 🔄 Conectando automaticamente ao WebSocket...');
        _webSocketService.connect();
      }
    });
  }

  // WebSocket service
  final WebSocketService _webSocketService = WebSocketService();
  bool _useWebSocket = true; // Flag para escolher entre RS485 e WebSocket

  bool get useWebSocket => _useWebSocket;
  bool get isWebSocketConnected => _webSocketService.isConnected;
  WebSocketService get webSocketService => _webSocketService;

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
    print('IPD Controller: 🔧 Inicializando WebSocket...');

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
  Map<String, dynamic> andares =
      {}; // Inicializa vazio - será preenchido pelo Python
  String? dataUltimaManutencao;

  Function()? onUpdate;
  Function()? onUpdateWeater;

  void _simulateData() {
    // Simular dados para demonstração no Linux
    temperatura = 25.0;
    capacidadeMaximaKg = 1000;
    capacidadePessoas = 8;
    latitude = -23.5505;
    longitude = -46.6333;
    direcaoMovimentacao = "Parado";
    mensagens = ["Sistema iniciado", "Linux mode ativo"];
    nomeObra = "Projeto Demo";
    codigoObra = "DEMO001";
    dataUltimaManutencao = "2024-01-01";

    // NOTA: Não preenchemos dados dos andares aqui
    // Eles virão do servidor Python via WebSocket
    print(
        'IPD Controller: ⏳ Aguardando dados dos andares do servidor Python...');
  }

  void _ensureValidAndares() {
    // Garante que o andar atual seja válido apenas para evitar crashes
    if (andarAtual < 0) {
      andarAtual = 1; // Fallback mínimo para evitar valores negativos
      print(
          'IPD Controller: ⚠️ Andar atual negativo, definindo para: $andarAtual');
    }

    // Se não temos dados dos andares ainda, aguardamos do Python
    if (andares.isEmpty) {
      print(
          'IPD Controller: ⏳ Aguardando dados dos andares do servidor Python...');
      return;
    }

    // Se temos dados mas o andar atual não existe, usamos o primeiro disponível
    if (!andares.containsKey(andarAtual.toString()) && andares.isNotEmpty) {
      final primeiroAndar = andares.keys.first;
      andarAtual = int.tryParse(primeiroAndar) ?? 1;
      print(
          'IPD Controller: ⚠️ Andar atual não encontrado, usando primeiro disponível: $andarAtual');
    }

    print('IPD Controller: 🏢 Andar atual: $andarAtual');
    print('IPD Controller: 🏢 Andares disponíveis: ${andares.keys.toList()}');
  }

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
          final novoAndar = dados["andar_atual"];
          if (novoAndar != null) {
            andarAtual = novoAndar is int
                ? novoAndar
                : int.tryParse(novoAndar.toString()) ?? andarAtual;
            print('IPD Controller: 🏢 Andar atualizado para: $andarAtual');
          }
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
          final novosAndares = dados["andares"];
          if (novosAndares is Map<String, dynamic> && novosAndares.isNotEmpty) {
            andares = Map<String, dynamic>.from(novosAndares);
            print(
                'IPD Controller: 🏢 Configuração de andares atualizada: $andares');

            // Se é a primeira vez que recebemos dados dos andares,
            // e o andar atual não existe, usamos o primeiro disponível
            if (!andares.containsKey(andarAtual.toString())) {
              final primeiroAndar = andares.keys.first;
              final novoAndar = int.tryParse(primeiroAndar);
              if (novoAndar != null) {
                andarAtual = novoAndar;
                print(
                    'IPD Controller: 🏢 Primeira configuração de andares - definindo andar atual para: $andarAtual');
              }
            }
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

        // Garantir que os dados dos andares sejam sempre válidos
        _ensureValidAndares();

        onUpdate?.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao processar a mensagem recebida: $e");
      }
    }
  }
}
