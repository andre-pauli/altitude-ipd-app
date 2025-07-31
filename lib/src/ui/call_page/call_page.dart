import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:altitude_ipd_app/src/ui/_core/enumerators.dart';
import 'package:altitude_ipd_app/src/ui/_core/firebase_config_support.dart';
import 'package:altitude_ipd_app/main.dart';
import 'package:altitude_ipd_app/src/services/telegram_service.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
      developer.log('Error initializing call: $e');
      if (mounted) {
        setState(() {
          isError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _initializeFirebaseParams() async {
    await initializeSupportApp();
    _supportDatabase = await getSupportDatabaseRef();
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
      developer.log('Error starting call process: $e');
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
    // Implementar autenticação com Google APIs se necessário
    return "your_access_token";
  }

  Future<void> sendPushNotification(String token, String roomId) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=YOUR_FCM_SERVER_KEY', // Substitua pela sua chave
    };

    final body = {
      'to': token,
      'notification': {
        'title': 'Nova chamada de suporte',
        'body': 'Cliente $roomId está solicitando suporte',
        'sound': 'default',
      },
      'data': {
        'type': 'new_call',
        'room_id': roomId,
      },
      'priority': 'high',
    };

    try {
      final response =
          await http.post(url, headers: headers, body: jsonEncode(body));
      if (response.statusCode == 200) {
        print('Push notification enviada com sucesso');
      } else {
        print('Erro ao enviar push notification: ${response.body}');
      }
    } catch (e) {
      print('Erro ao enviar push notification: $e');
    }
  }

  void _listenForCallStatus() {
    _callStatusSubscription =
        _supportDatabase.ref("calls/$roomId/status").onValue.listen((event) {
      if (event.snapshot.exists) {
        final status = event.snapshot.value as String;
        _handleCallStatusChange(status);
      }
    });
  }

  void _handleCallStatusChange(String status) {
    if (status == "active") {
      _callingTimer?.cancel();
      setState(() {
        inCall = true;
      });
    } else if (status == "declined") {
      _callingTimer?.cancel();
      setState(() {
        isDeclined = true;
      });
    } else if (status == "ended") {
      _stopCallProcess(context: context, endCallRemotely: false);
    }
  }

  Future<void> _startWebRTC() async {
    try {
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {
            'urls': 'turn:your-turn-server.com:3478',
            'username': 'username',
            'credential': 'password'
          }
        ],
        'sdpSemantics': 'unified-plan'
      });

      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
        await _sendIceCandidate(candidate);
      };

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.callPageType == CallPageType.video,
      });

      _localRenderer?.srcObject = _localStream;

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          setState(() {
            _remoteRenderer?.srcObject = event.streams.first;
            inCall = true;
          });
        }
      };

      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        developer.log('Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _handleConnectionError();
        }
      };

      _listenForOffer();
      _listenForIceCandidates();
      _monitorCallStatus();
    } catch (e) {
      developer.log('Error in signaling: $e');
      throw e;
    }
  }

  Future<void> _listenForOffer() async {
    _answerSubscription = _supportDatabase
        .ref("calls/$roomId/answer")
        .onValue
        .listen((event) async {
      if (event.snapshot.exists) {
        final answerData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        final answer = RTCSessionDescription(
          answerData['sdp'],
          answerData['type'],
        );

        await _peerConnection?.setRemoteDescription(answer);
        print('Answer recebida e processada');
      }
    });
  }

  Future<void> _listenForIceCandidates() async {
    _iceCandidatesSubscription = _supportDatabase
        .ref("calls/$roomId/ice_candidates/callee")
        .onValue
        .listen((event) async {
      if (event.snapshot.exists) {
        final candidates =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        for (var candidateData in candidates.values) {
          if (candidateData is Map<String, dynamic>) {
            final candidate = RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'],
              candidateData['sdpMLineIndex'],
            );
            await _peerConnection?.addCandidate(candidate);
          }
        }
      }
    });
  }

  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    final candidateData = {
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };

    await _supportDatabase
        .ref(
            "calls/$roomId/ice_candidates/caller/${DateTime.now().millisecondsSinceEpoch}")
        .set(candidateData);
  }

  void _monitorCallStatus() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || isCallEnded) {
        timer.cancel();
        return;
      }

      try {
        final snapshot =
            await _supportDatabase.ref("calls/$roomId/status").get();
        if (!snapshot.exists) {
          timer.cancel();
          _stopCallProcess(context: context, endCallRemotely: false);
        }
      } catch (e) {
        print('Erro ao monitorar status da chamada: $e');
      }
    });
  }

  void _handleConnectionError() {
    setState(() {
      isError = true;
      errorMessage = 'Erro na conexão WebRTC';
    });
  }

  Future<void> _stopWbrtcProccess() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }

  Future<void> _stopCallProcess({
    required BuildContext context,
    required bool endCallRemotely,
  }) async {
    if (isStoppingCall) return;

    setState(() {
      isStoppingCall = true;
    });

    try {
      await _stopWbrtcProccess();

      if (endCallRemotely) {
        await _supportDatabase.ref('calls/$roomId/status').set("ended");
        await _supportDatabase.ref("calls/$roomId").remove();
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const IpdHomePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Erro ao parar chamada: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (_remoteRenderer != null && inCall)
              RTCVideoView(
                _remoteRenderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),

            // Local video (picture-in-picture)
            if (_localRenderer != null && inCall)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: RTCVideoView(
                      _localRenderer!,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // Call controls overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Call duration
                    ValueListenableBuilder<Duration>(
                      valueListenable: _callDuration,
                      builder: (context, duration, child) {
                        return Text(
                          '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Call controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute button
                        _buildControlButton(
                          icon: Icons.mic,
                          onPressed: () {
                            // Implementar mute/unmute
                          },
                        ),

                        // End call button
                        _buildControlButton(
                          icon: Icons.call_end,
                          backgroundColor: Colors.red,
                          onPressed: () {
                            _stopCallProcess(
                              context: context,
                              endCallRemotely: true,
                            );
                          },
                        ),

                        // Switch camera button (video calls only)
                        if (widget.callPageType == CallPageType.video)
                          _buildControlButton(
                            icon: Icons.switch_camera,
                            onPressed: () {
                              // Implementar troca de câmera
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (isCalling && !inCall)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Conectando...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

            // Error overlay
            if (isError)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Erro na conexão',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        errorMessage,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _stopCallProcess(
                            context: context,
                            endCallRemotely: false,
                          );
                        },
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              ),

            // Declined overlay
            if (isDeclined)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_end,
                        color: Colors.red,
                        size: 64,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Chamada recusada',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'O suporte não está disponível no momento',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 24,
      ),
    );
  }
}
