import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:altitude_ipd_app/src/ui/_core/enumerators.dart';
import 'package:altitude_ipd_app/src/ui/_core/firebase_config_support.dart';
import 'package:altitude_ipd_app/main.dart';
import 'package:altitude_ipd_app/src/services/telegram_service.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CallPage extends StatefulWidget {
  final CallPageType callPageType;
  final String roomId;
  final List<String> mensagens;

  const CallPage({
    Key? key,
    required this.callPageType,
    required this.roomId,
    required this.mensagens,
  }) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final IpdHomeController controller = IpdHomeController();
  late FirebaseDatabase _supportDatabase;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;
  final ValueNotifier<Duration> _callDuration = ValueNotifier(Duration.zero);

  late String roomId;
  static const int call_time = 100;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool inCall = false;
  bool isDeclined = false;
  bool isCalling = false;
  bool isCallEnded = false;
  bool isStoppingCall = false;
  bool isError = false;
  String errorMessage = '';

  // Add stream subscriptions to properly dispose them
  StreamSubscription? _callStatusSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidatesSubscription;
  Timer? _callingTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    controller.onUpdate = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _cleanupResources();
    _callingTimer?.cancel();
    _callStatusSubscription?.cancel();
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cleanupResources() async {
    _callingTimer?.cancel();
    _callStatusSubscription?.cancel();
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();

    await _stopWbrtcProccess();
  }

  void _initialize() async {
    try {
      roomId = widget.roomId;
      await _initializeFirebaseParams();

      if (await checkDatabaseInstance()) {
        await _initializeRenderers();
        await _startCallProcess();
        _startCallTimer();
      } else {
        await _stopCallProcess(context: context, endCallRemotely: false);
      }
    } catch (e) {
      log('Error initializing call: $e');
      if (mounted) {
        await _stopCallProcess(context: context, endCallRemotely: false);
      }
    }
  }

  Future<void> _initializeRenderers() async {
    if (!mounted) return;

    setState(() {
      isCalling = true;
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
    });

    await _localRenderer?.initialize();
    await _remoteRenderer?.initialize();
  }

  void _startCallTimer() {
    _callingTimer?.cancel();
    _callingTimer = Timer(const Duration(seconds: call_time), () {
      if (mounted) {
        setState(() {
          isDeclined = true;
        });
      }
    });
  }

  Future<void> _startCallProcess() async {
    try {
      await _supportDatabase.ref("calls/$roomId").set({
        "status": "pending",
        "offer": null,
        "answer": null,
        'room_id': roomId,
        'type': 'new_call',
        'client_name': roomId,
        'call_type': widget.callPageType.name,
        "ice_candidates": {"caller": {}, "callee": {}}
      });

      await _sendPushNotificationToSupport();
      _listenForCallStatus();
      await _startWebRTC();
    } catch (e) {
      log('Error starting call process: $e');
      if (mounted) {
        await _stopCallProcess(context: context, endCallRemotely: false);
      }
    }
  }

  Future<void> _sendMessageTelegram() async {
    TelegramService _telegramService = TelegramService();
    await _telegramService.sendMessage(
        "O cliente $roomId fez um chamado pro S.O.S \n Ele está com os seguintes erros: \n ${widget.mensagens.join('\n')}");
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
          "title": "S.O.S Altitude",
          "body": "O usuário $roomId está tentando realizar uma chamada.",
        },
        "data": {
          "type": "new_call",
          "room_id": roomId,
          "client_name": roomId,
          "call_type": widget.callPageType.name,
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
    _callStatusSubscription?.cancel();
    _callStatusSubscription = _supportDatabase
        .ref("calls/$roomId/status")
        .onValue
        .listen((event) async {
      if (!mounted) return;

      final status = event.snapshot.value as String?;
      if (status == "active") {
        _callingTimer?.cancel();
        setState(() {
          inCall = true;
        });
      } else if (status == "declined") {
        setState(() {
          isDeclined = true;
        });
      } else if (status == "ended") {
        await _stopCallProcess(context: context, endCallRemotely: false);
      }
    });
  }

  Future<void> _startWebRTC() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'}
      ],
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 10
    });

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('Connection state changed: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _handleConnectionError();
      }
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      log('ICE connection state changed: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _handleConnectionError();
      }
    };

    _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('ICE gathering state changed: $state');
    };

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      log('New ICE candidate: ${candidate.candidate}');
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
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'channelCount': 1,
        'sampleRate': 48000,
      },
      'video': widget.callPageType == CallPageType.video
          ? {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'facingMode': 'user',
              'frameRate': {'ideal': 30},
            }
          : false,
    });

    _localRenderer!.srcObject = _localStream;

    _localStream?.getTracks().forEach((track) {
      track.enabled = true;
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer!.srcObject = event.streams.first;
          inCall = true;
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
    _answerSubscription?.cancel();
    _answerSubscription = _supportDatabase
        .ref("calls/$roomId/answer")
        .onValue
        .listen((event) async {
      if (!mounted) return;

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
    _iceCandidatesSubscription?.cancel();
    _iceCandidatesSubscription = _supportDatabase
        .ref("calls/$roomId/ice_candidates/$receiver")
        .onChildAdded
        .listen((event) async {
      if (!mounted) return;

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

    if (isError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _attemptReconnection,
                child: const Text('Tentar Reconectar'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _stopCallProcess(
                  context: context,
                  endCallRemotely: true,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Encerrar Chamada'),
              ),
            ],
          ),
        ),
      );
    }

    if (isDeclined) {
      return _buildDeclinedScreen();
    }

    if (isCallEnded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Encerrando a chamada...'),
            ],
          ),
        ),
      );
    }

    if (_remoteRenderer == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Iniciando chamada...'),
              if (isCalling) ...[
                const SizedBox(height: 8),
                const Text(
                  'Aguardando resposta...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
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
                _cleanupResources();
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
          child: _remoteRenderer!.srcObject == null
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
                  _remoteRenderer!,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
        Positioned(
          bottom: 40.0 * heightRatio,
          right: 40.0 * widthRatio,
          width: 400 * widthRatio,
          height: 450 * heightRatio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _localRenderer!.srcObject == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RTCVideoView(
                    _localRenderer!,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),
        ),
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
                _remoteRenderer!.srcObject == null
                    ? Text('Chamando...')
                    : buildTimerWidget(),
                Image.asset('assets/images/png/logo_altitude.png'),
              ],
            ),
          ),
        ),
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

  Future<void> _stopWbrtcProccess() async {
    try {
      if (_localRenderer?.srcObject != null) {
        _localRenderer!.srcObject?.getTracks().forEach((track) {
          track.stop();
          track.enabled = false;
        });
        _localRenderer!.srcObject = null;
      }

      if (_localRenderer != null) {
        await _localRenderer!.dispose();
        _localRenderer = null;
      }

      if (_remoteRenderer?.srcObject != null) {
        _remoteRenderer!.srcObject?.getTracks().forEach((track) {
          track.stop();
          track.enabled = false;
        });
        _remoteRenderer!.srcObject = null;
      }

      if (_remoteRenderer != null) {
        await _remoteRenderer!.dispose();
        _remoteRenderer = null;
      }

      if (_peerConnection != null) {
        _peerConnection?.onIceCandidate = null;
        _peerConnection?.onIceConnectionState = null;
        _peerConnection?.onConnectionState = null;
        _peerConnection?.onIceGatheringState = null;
        _peerConnection?.onTrack = null;
        await _peerConnection?.close();
        _peerConnection = null;
      }

      if (_localStream != null) {
        _localStream?.getTracks().forEach((track) {
          track.stop();
          track.enabled = false;
        });
        await _localStream?.dispose();
        _localStream = null;
      }
    } catch (e) {
      log('Error stopping WebRTC: $e');
    }
  }

  Future<void> _stopCallProcess({
    bool endCallRemotely = false,
    required BuildContext context,
  }) async {
    if (isStoppingCall) return;

    try {
      if (!mounted) return;

      setState(() {
        isStoppingCall = true;
        isCallEnded = true;
      });

      if (endCallRemotely && await checkDatabaseInstance()) {
        await _supportDatabase.ref('calls/$roomId/status').set("ended");
      }

      await _stopWbrtcProccess();

      if (await checkDatabaseInstance()) {
        await _supportDatabase.ref("calls/$roomId").remove();
      }

      if (mounted) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const IpdHomePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      log('Error stopping call process: $e');
    } finally {
      if (mounted) {
        setState(() {
          isStoppingCall = false;
        });
      }
    }
  }

  void _handleConnectionError() {
    if (!mounted) return;

    setState(() {
      isError = true;
      errorMessage = 'Erro na conexão. Tentando reconectar...';
    });

    _attemptReconnection();
  }

  Future<void> _attemptReconnection() async {
    try {
      await _stopWbrtcProccess();
      await Future.delayed(const Duration(seconds: 2));
      await _startWebRTC();
    } catch (e) {
      log('Reconnection failed: $e');
      if (mounted) {
        setState(() {
          isError = true;
          errorMessage = 'Falha na reconexão. Por favor, tente novamente.';
        });
      }
    }
  }
}
