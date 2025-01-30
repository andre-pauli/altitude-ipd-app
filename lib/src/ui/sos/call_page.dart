import 'dart:async';
import 'dart:convert';

import 'package:altitude_ipd_app/firebase_config_support.dart';
import 'package:altitude_ipd_app/main.dart';
import 'package:altitude_ipd_app/src/services/telegram_service.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

enum CallPageType { audio, video }

class CallPage extends StatefulWidget {
  final CallPageType callPageType;
  final String roomId;
  List<String> mensagens = [];
  CallPage(
      {Key? key,
      required this.callPageType,
      required this.roomId,
      required this.mensagens})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final IpdHomeController controller = IpdHomeController();
  late FirebaseDatabase _supportDatabase;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Timer? _callingTimer;
  Timer? _callTimer;
  final ValueNotifier<Duration> _callDuration = ValueNotifier(Duration.zero);

  late String roomId;
  static const int call_time = 100;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool inCall = false;
  bool isDeclined = false;
  bool isCalling = false;

  @override
  void initState() {
    super.initState();
    controller.onUpdate = () {
      setState(() {});
    };
    controller.enviarComandoBooleano(
        acao: "enviar_notificacao_telegram_sos", estado: true);
    _initialize();
  }

  @override
  void dispose() {
    _stopWbrtcProccess();
    super.dispose();
  }

  void _initialize() async {
    roomId = widget.roomId;
    await _initializeFirebaseParams();
    await _initializeRenderers();
    await _startCallProcess();
    await _sendMessageTelegram();
    _startCallTimer();
  }

  Future<void> _sendMessageTelegram() async {
    TelegramService _telegramService = TelegramService();
    await _telegramService.sendMessage(
        "O cliente $roomId fez um chamado pro S.O.S \n Ele está com os seguintes erros: \n ${widget.mensagens.join('\n')}");
  }

  Future<void> _initializeRenderers() async {
    setState(() {
      isCalling = true;
    });
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startCallTimer() {
    const duration = Duration(seconds: call_time); // Tempo limite da chamada
    _callingTimer = Timer(duration, () {
      print('Tempo de chamada expirado. Finalizando a chamada...');
      setState(() {
        isDeclined = true;
      }); // Finaliza a chamada
    });
  }

  Future<void> _startCallProcess() async {
    // Criar a chamada no Firebase com status "pending"
    await _supportDatabase.ref("calls/$roomId").set({
      "status": "pending",
      "offer": null,
      "answer": null,
      "ice_candidates": {"caller": {}, "callee": {}}
    });

    await _sendPushNotificationToSupport();
    _listenForCallStatus();
  }

  Future<void> _sendPushNotificationToSupport() async {
    final tokensSnapshot =
        await _supportDatabase.ref("support_fcm_tokens").get();

    if (tokensSnapshot.exists) {
      final tokens = Map<String, dynamic>.from(tokensSnapshot.value as Map);

      for (var tokenEntry in tokens.entries) {
        final token = tokenEntry.value['token'];
        await sendPushNotification(token, widget.roomId);
      }
    } else {
      print("Nenhum token FCM encontrado.");
    }
  }

  Future<String> getAccessToken() async {
    final credentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "0298213e5b0b94e0cf205371ecac7cdc9f9cacf3",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC/PrcmkKB7qFCb\nfB5zcPbItB6tm6yqjvZwXkjyms6VIfHfYwxDL0If63Q6YE6IB8ohbcuhO1DVCKZZ\nzUgN3DTgOcX5CSb1TveQteQXKxpEMjq1Kj33G1hRatDI9QA9RiSjyXtncYseXjRA\nENtZ1GpqMY0rmJzlG2AdUgdcSQc+EaEd8IYKUF2mDlkLqFu5oR2YdSyz42AOADJf\nDA4K+vGwlsaOeU85uLftuRX+Itp3WAOMhENqQQuUs5evv6An9ZYCrAXiy9nw42ug\n1P/jE3L1HK899AK//V8u8YC8VGslyzT4KUNFP2Lu8PjZKe+nVnknVaJhqsVFS36W\n2JZX+bU5AgMBAAECggEAAl2pgN/hqF3271F8A/QWDXoS9hVar7p4iH/WGbA6FYS3\nvAp65JrhT8lHJRC7b/nesYas8ffsolIK0soUFd3PRqXYUeIf2gGJ1P+3DGVTXBwd\n909IOHYdY9Z1MkM7p0ZmniMYNHmmXbAPJ+q9d/FFhr5Jr4wiBsCNshcpcaYSoZ0r\nMkLMn0JLnYshqxt3kXd0hGi/h/psJsui0qwvgx0gIO8dnGkan+wcdqeGGqz2EraY\nZrpcRAgxrIgHb0I4QX9pbUs/oC/VGxLPbDL1rehxEW8Vq0qz2tqWoPKX4j+RJXQA\nETJPrLM6ZS59BiWMh/iSBy0EsHhO60RP6fMzdOdbjQKBgQD8SY7uTcFWZCA0cOKq\n/qV53VHEJIKTiI8RkTxnwaxbxROLMIrrhonz8WO5/BFbw65R7pSc8LoUNGkGGssF\nBPr6VlJJJXdF/XyDpks2d/9LjsgD3UA3r43NG7pSiEJi9qA4hxsaEbMh3rMki4kA\nsY0NjPal47VbqLslMduRJULkpQKBgQDCDzE9aWH+Y2bGMl8r+bt3kV/lDgLmL8fs\nhxQwfk+JCLjRQ6fOfxZUmPPyFmn8edN+1fq0KkjvGGR4tD7iHQFrsTB6NtTDBz4E\nUJ6B3LaKHPKsXTDJY39xYgF54JF5I9VUojGlNhrJ0JMEzuh5pmu4QRN751fihdXW\nbjAfnBPmBQKBgFucgnB6f7hVR3SDgWvCaGhmO6jT8S6NqhYg/SRYKbRxTfV/PRLl\nmfahMyt4Iv2FgylxTznmGEv59CEpXYuHEXQSIHM7TaJ2t94+ZpVy4ZuYT31HvGf8\nMavHY9NQc3roP6oHNYoz3y5vZfHhUXCVCLlg9LeshlCwZrTM9AQy2aWZAoGALhhL\nuumgRDu6OtPWNWzhcbpPS+ozGBg7ZdyEGCy4mbU/qT1ny632UOvv7g4S6MzLRvJu\n1YLBxkFGBEHUOgNnxfvVpwIFMbozqfS4YeJaXZ4YqoaMQxnmOLlt3lRQWbUARFUu\nc67RWCS590dqgxLbvW1/wkumXYEq1P9hYPDC7T0CgYAF6qJYjRV7gBeQO2vdT9YP\n2+6d7ApY/CTOUFp1vs5QbOTxr2BRfXeGruCuvBPSNuNhzfHEf0yM7tBhoaUWxefq\n/SJtBWiyLe2p/B6HJZ01NqsWwhCKnAhVSCaQDW+sEIqdKktzuwEU5UGdL2uDTtUF\nZ4rFJND0cxBglZmkx3ULWA==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "support-app-messaging@altitude-support-capp-app.iam.gserviceaccount.com",
      "client_id": "107866117364749390698",
      "type": "service_account",
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }

  Future<void> sendPushNotification(String token, String roomId) async {
    const fcmUrl =
        "https://fcm.googleapis.com/v1/projects/altitude-support-capp-app/messages:send";

    final accessToken = await getAccessToken();

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };

    final body = {
      "message": {
        "token": token,
        "notification": {
          "title": "🚀 Nova Chamada de Suporte",
          "body": "📞 Um usuário está tentando realizar uma chamada.",
        },
        "data": {
          "type": "new_call",
          "room_id": roomId,
          "call_type":
              widget.callPageType == CallPageType.audio ? "audio" : "video",
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print(body.toString());

      if (response.statusCode == 200) {
        print("Push notification enviada com sucesso!");
      } else {
        print("Erro ao enviar push notification: ${response.body}");
      }
    } catch (e) {
      print("Erro ao enviar push notification: $e");
    }
  }

  void _listenForCallStatus() {
    _supportDatabase.ref("calls/$roomId/status").onValue.listen((event) async {
      if (event.snapshot.value == "active") {
        await _startWebRTC();
      } else if (event.snapshot.value == "declined") {
        setState(() {
          isDeclined = true;
        });
      } else if (event.snapshot.value == "ended") {
        _stopCallProcess(context: context, endCallRemotely: false);
      }
    });
  }

  Future<void> _startWebRTC() async {
    // Configuração inicial do PeerConnection
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    });

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      await _supportDatabase
          .ref("calls/$roomId/ice_candidates/caller")
          .push()
          .set({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.callPageType == CallPageType.video,
    });
    _localRenderer.srcObject = _localStream;

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams.first;
        });
      }
    };

    var offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    await _supportDatabase.ref("calls/$roomId/offer").set({
      'sdp': offer!.sdp,
      'type': offer.type,
    });

    _listenForAnswer();
    _listenForIceCandidates("callee");
  }

  Future<void> _listenForAnswer() async {
    _supportDatabase.ref("calls/$roomId/answer").onValue.listen((event) async {
      if (event.snapshot.value != null) {
        var answerData = event.snapshot.value as Map;
        var answer =
            RTCSessionDescription(answerData['sdp'], answerData['type']);
        await _peerConnection?.setRemoteDescription(answer);

        setState(() {
          inCall = true;
        });
      }
    });
  }

  Future<void> _listenForIceCandidates(String receiver) async {
    _supportDatabase
        .ref("calls/$roomId/ice_candidates/$receiver")
        .onChildAdded
        .listen((event) async {
      if (event.snapshot.value != null) {
        var candidateData = event.snapshot.value as Map;
        var candidate = RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;
    if (isDeclined) {
      return _buildDeclinedScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.callPageType == CallPageType.video
          ? buildVideoCallWidget(
              widthRatio: widthRatio, heightRatio: heightRatio)
          : buildAudioCallWidget(
              widthRatio: widthRatio, heightRatio: heightRatio),
    );
  }

  Widget _buildDeclinedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'O suporte não está disponível no momento.',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _stopWbrtcProccess();
                Navigator.of(context).pop();
              },
              child: const Text('Tentar novamente'),
            ),
            ElevatedButton(
              onPressed: () {
                _stopCallProcess(context: context, endCallRemotely: true);
              },
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVideoCallWidget(
      {required double widthRatio, required double heightRatio}) {
    return Stack(
      children: [
        Container(
          child: _remoteRenderer.srcObject == null
              ? Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chamando...'),
                    Image.asset('assets/images/png/logo_altitude.png'),
                  ],
                ))
              : RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
        Positioned(
          bottom: 40.0 * heightRatio, // Margem do topo
          right: 40.0 * widthRatio, // Margem do canto esquerdo
          width: 400 * widthRatio, // Largura do vídeo local
          height: 450 * heightRatio, // Altura do vídeo local
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2), // Borda branca
              borderRadius: BorderRadius.circular(8), // Cantos arredondados
            ),
            child: _localRenderer.srcObject == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
        ),
        // Botão de finalizar chamada centralizado
        Padding(
          padding: EdgeInsets.only(bottom: 40.0 * heightRatio),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: () =>
                  _stopCallProcess(context: context, endCallRemotely: true),
              tooltip: 'Finalizar Chamada',
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ),
        ),
      ],
    );
  }

  void _stopCallProcess({
    bool endCallRemotely = false,
    required BuildContext context,
  }) async {
    try {
      // Atualizar o status no Firebase para "ended", se necessário
      if (endCallRemotely) {
        await _supportDatabase.ref('calls/$roomId/status').set("ended");
      }

      _stopWbrtcProccess();

      // Remover os dados da chamada no Firebase
      await _supportDatabase.ref("calls/$roomId").remove();

      navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => IpdHomePage(),
          ),
          (route) => false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => IpdHomePage()),
        (route) => false,
      );
    } catch (e) {
      print("Erro ao finalizar a chamada: $e");
    }
  }

  Widget buildAudioCallWidget(
      {required double widthRatio, required double heightRatio}) {
    return Stack(
      children: [
        Container(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _remoteRenderer.srcObject == null
                    ? Text('Chamando...')
                    : buildTimerWidget(),
                Image.asset('assets/images/png/logo_altitude.png'),
              ],
            ),
          ),
        ),
        // Botão de finalizar chamada centralizado
        Padding(
          padding: EdgeInsets.only(bottom: 40.0 * heightRatio),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingActionButton(
              onPressed: () =>
                  _stopCallProcess(context: context, endCallRemotely: true),
              tooltip: 'Finalizar Chamada',
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTimerWidget() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _callDuration,
      builder: (context, duration, child) {
        final minutes =
            duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds =
            duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        return Text(
          '$minutes:$seconds',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Future<void> _initializeFirebaseParams() async {
    await initializeSupportApp();
    _supportDatabase = await getSupportDatabaseRef();
  }

  void _stopWbrtcProccess() async {
    if (_localRenderer.srcObject != null) {
      _localRenderer.srcObject?.getTracks().forEach((track) => track.stop());
      _localRenderer.srcObject = null;
      _localRenderer.dispose();
    }

    if (_remoteRenderer.srcObject != null) {
      _remoteRenderer.srcObject?.getTracks().forEach((track) => track.stop());
      _remoteRenderer.srcObject = null;
      _remoteRenderer.dispose();
    }

    await _peerConnection?.close();
    _peerConnection = null;

    if (_localStream != null) {
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream = null;
    }
  }
}
