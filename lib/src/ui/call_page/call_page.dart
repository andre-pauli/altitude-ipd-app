// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';

// import 'package:altitude_ipd_app/src/ui/_core/enumerators.dart';
// import 'package:altitude_ipd_app/src/ui/_core/firebase_config_support.dart';
// import 'package:altitude_ipd_app/main.dart';
// import 'package:altitude_ipd_app/src/services/telegram_service.dart';
// import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
// import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_page.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// // import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';

// class CallPage extends StatefulWidget {
//   final CallPageType callPageType;
//   final String roomId;
//   final List<String> mensagens;

//   const CallPage({
//     Key? key,
//     required this.callPageType,
//     required this.roomId,
//     required this.mensagens,
//   }) : super(key: key);

//   @override
//   _CallPageState createState() => _CallPageState();
// }

// class _CallPageState extends State<CallPage> {
//   final IpdHomeController controller = IpdHomeController();
//   late FirebaseDatabase _supportDatabase;
//   RTCVideoRenderer? _localRenderer;
//   RTCVideoRenderer? _remoteRenderer;
//   final ValueNotifier<Duration> _callDuration = ValueNotifier(Duration.zero);

//   late String roomId;
//   static const int call_time = 100;

//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   bool inCall = false;
//   bool isDeclined = false;
//   bool isCalling = false;
//   bool isCallEnded = false;
//   bool isStoppingCall = false;
//   bool isError = false;
//   bool isInitializing = true;
//   String errorMessage = '';
//   bool isMuted = false;
//   bool isCameraOff = false;

//   // Stream subscriptions
//   StreamSubscription? _callStatusSubscription;
//   StreamSubscription? _answerSubscription;
//   StreamSubscription? _iceCandidatesSubscription;
//   Timer? _callingTimer;
//   Timer? _callDurationTimer;

//   // WebRTC configuration
//   final Map<String, dynamic> _configuration = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//       {'urls': 'stun:stun2.l.google.com:19302'},
//       {'urls': 'stun:stun3.l.google.com:19302'},
//       {'urls': 'stun:stun4.l.google.com:19302'}
//     ],
//     'sdpSemantics': 'unified-plan',
//     'iceCandidatePoolSize': 10
//   };

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//     controller.onUpdate = () {
//       if (mounted) setState(() {});
//     };
//   }

//   @override
//   void dispose() {
//     _cleanupResources();
//     _callingTimer?.cancel();
//     _callDurationTimer?.cancel();
//     _callStatusSubscription?.cancel();
//     _answerSubscription?.cancel();
//     _iceCandidatesSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _cleanupResources() async {
//     try {
//       log('=== LIMPANDO RECURSOS ===');

//       // Cancela timers
//       log('Cancelando timers...');
//       _callingTimer?.cancel();
//       _callDurationTimer?.cancel();
//       log('Timers cancelados');

//       // Cancela subscriptions
//       log('Cancelando subscriptions...');
//       _callStatusSubscription?.cancel();
//       _answerSubscription?.cancel();
//       _iceCandidatesSubscription?.cancel();
//       log('Subscriptions cancelados');

//       // Para tracks de mídia
//       if (_localStream != null) {
//         log('Parando tracks de mídia...');
//         _localStream!.getTracks().forEach((track) {
//           track.stop();
//           track.enabled = false;
//           log('Track ${track.kind} parada');
//         });
//         await _localStream?.dispose();
//         _localStream = null;
//         log('Stream local descartado');
//       }

//       // Limpa renderers
//       if (_localRenderer != null) {
//         log('Limpando renderer local...');
//         _localRenderer!.srcObject = null;
//         await _localRenderer?.dispose();
//         _localRenderer = null;
//         log('Renderer local descartado');
//       }

//       if (_remoteRenderer != null) {
//         log('Limpando renderer remoto...');
//         _remoteRenderer!.srcObject = null;
//         await _remoteRenderer?.dispose();
//         _remoteRenderer = null;
//         log('Renderer remoto descartado');
//       }

//       // Fecha peer connection
//       if (_peerConnection != null) {
//         log('Fechando peer connection...');
//         _peerConnection?.onIceCandidate = null;
//         _peerConnection?.onIceConnectionState = null;
//         _peerConnection?.onConnectionState = null;
//         _peerConnection?.onIceGatheringState = null;
//         _peerConnection?.onTrack = null;
//         await _peerConnection?.close();
//         _peerConnection = null;
//         log('Peer connection fechada');
//       }

//       log('=== RECURSOS LIMPOS COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO ao limpar recursos: $e');
//     }
//   }

//   void _initialize() async {
//     try {
//       log('=== INICIANDO CALL PAGE ===');
//       log('Tipo de chamada: ${widget.callPageType}');
//       log('Room ID: ${widget.roomId}');

//       roomId = widget.roomId;
//       await _initializeFirebaseParams();

//       if (await FirebaseConfigSupport.checkDatabaseInstance()) {
//         log('Firebase configurado com sucesso');
//         await _checkPermissions();
//         await _initializeRenderers();
//         await _startCallProcess();
//       } else {
//         log('ERRO: Firebase não configurado');
//         await _stopCallProcess(context: context, endCallRemotely: false);
//       }

//       setState(() {
//         isInitializing = false;
//       });
//       log('=== CALL PAGE INICIADA COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO ao inicializar call: $e');
//       if (mounted) {
//         setState(() {
//           isError = true;
//           errorMessage = 'Erro ao inicializar: $e';
//           isInitializing = false;
//         });
//       }
//     }
//   }

//   Future<void> _initializeFirebaseParams() async {
//     await FirebaseConfigSupport.initializeSupportApp();
//     _supportDatabase = await FirebaseConfigSupport.getSupportDatabaseRef();
//   }

//   Future<void> _checkPermissions() async {
//     try {
//       // Permissão de microfone sempre necessária
//       var micStatus = await Permission.microphone.status;
//       if (!micStatus.isGranted) {
//         micStatus = await Permission.microphone.request();
//         if (!micStatus.isGranted) {
//           throw Exception('Permissão de microfone negada');
//         }
//       }

//       // Permissão de câmera apenas para chamadas de vídeo
//       if (widget.callPageType == CallPageType.video) {
//         var cameraStatus = await Permission.camera.status;
//         if (!cameraStatus.isGranted) {
//           cameraStatus = await Permission.camera.request();
//           if (!cameraStatus.isGranted) {
//             throw Exception('Permissão de câmera negada');
//           }
//         }
//       }

//       log('Permissões verificadas com sucesso');
//     } catch (e) {
//       log('Erro ao verificar permissões: $e');
//       rethrow;
//     }
//   }

//   Future<void> _initializeRenderers() async {
//     if (!mounted) return;

//     try {
//       log('Inicializando renderer local...');
//       _localRenderer = RTCVideoRenderer();
//       await _localRenderer?.initialize();
//       log('Renderer local inicializado');

//       log('Inicializando renderer remoto...');
//       _remoteRenderer = RTCVideoRenderer();
//       await _remoteRenderer?.initialize();
//       log('Renderer remoto inicializado');

//       log('Renderers inicializados com sucesso');
//     } catch (e) {
//       log('ERRO ao inicializar renderers: $e');
//       rethrow;
//     }
//   }

//   void _startCallTimer() {
//     _callingTimer?.cancel();
//     _callingTimer = Timer(const Duration(seconds: call_time), () {
//       if (mounted) {
//         setState(() {
//           isDeclined = true;
//         });
//       }
//     });
//   }

//   void _startCallDurationTimer() {
//     _callDurationTimer?.cancel();
//     _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted && inCall) {
//         _callDuration.value = _callDuration.value + const Duration(seconds: 1);
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   Future<void> _startCallProcess() async {
//     try {
//       log('=== INICIANDO PROCESSO DE CHAMADA ===');

//       // Cria entrada no Firebase
//       log('Criando entrada no Firebase...');
//       await _supportDatabase.ref("calls/$roomId").set({
//         "status": "pending",
//         "offer": null,
//         "answer": null,
//         'room_id': roomId,
//         'type': 'new_call',
//         'client_name': roomId,
//         'call_type': widget.callPageType.name,
//         "ice_candidates": {"caller": {}, "callee": {}},
//         'created_at': DateTime.now().toIso8601String(),
//       });
//       log('Entrada no Firebase criada com sucesso');

//       // Envia notificação push
//       log('Enviando notificação push...');
//       await _sendPushNotificationToSupport();
//       log('Notificação push enviada');

//       // Inicia timer de chamada
//       log('Iniciando timer de chamada...');
//       _startCallTimer();

//       // Escuta por mudanças no status
//       log('Configurando listeners...');
//       _listenForCallStatus();

//       // Inicia WebRTC
//       log('Iniciando WebRTC...');
//       await _startWebRTC();

//       setState(() {
//         isCalling = true;
//       });
//       log('=== PROCESSO DE CHAMADA INICIADO COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO ao iniciar processo de chamada: $e');
//       if (mounted) {
//         setState(() {
//           isError = true;
//           errorMessage = 'Erro ao iniciar chamada: $e';
//         });
//       }
//     }
//   }

//   Future<void> _sendMessageTelegram() async {
//     try {
//       TelegramService _telegramService = TelegramService();
//       await _telegramService.sendMessage(
//           "O cliente $roomId fez um chamado pro S.O.S \n Ele está com os seguintes erros: \n ${widget.mensagens.join('\n')}");
//     } catch (e) {
//       log('Erro ao enviar mensagem Telegram: $e');
//     }
//   }

//   Future<void> _sendPushNotificationToSupport() async {
//     try {
//       log('Buscando tokens FCM do suporte...');
//       final tokensSnapshot =
//           await _supportDatabase.ref("support_fcm_tokens").get();

//       if (tokensSnapshot.exists) {
//         final tokens = Map<String, dynamic>.from(tokensSnapshot.value as Map);
//         log('Tokens encontrados: ${tokens.length}');

//         for (var tokenEntry in tokens.entries) {
//           final token = tokenEntry.value['token'];
//           log('Enviando notificação para token: ${tokenEntry.key}');
//           await sendPushNotification(token, widget.roomId);
//         }
//         log('Todas as notificações push enviadas');
//       } else {
//         log("Nenhum token FCM encontrado para o suporte");
//       }
//     } catch (e) {
//       log('ERRO ao enviar push notification: $e');
//     }
//   }

//   Future<String> getAccessToken() async {
//     final credentials = ServiceAccountCredentials.fromJson({
//       "private_key_id": "0298213e5b0b94e0cf205371ecac7cdc9f9cacf3",
//       "private_key":
//           "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC/PrcmkKB7qFCb\nfB5zcPbItB6tm6yqjvZwXkjyms6VIfHfYwxDL0If63Q6YE6IB8ohbcuhO1DVCKZZ\nzUgN3DTgOcX5CSb1TveQteQXKxpEMjq1Kj33G1hRatDI9QA9RiSjyXtncYseXjRA\nENtZ1GpqMY0rmJzlG2AdUgdcSQc+EaEd8IYKUF2mDlkLqFu5oR2YdSyz42AOADJf\nDA4K+vGwlsaOeU85uLftuRX+Itp3WAOMhENqQQuUs5evv6An9ZYCrAXiy9nw42ug\n1P/jE3L1HK899AK//V8u8YC8VGslyzT4KUNFP2Lu8PjZKe+nVnknVaJhqsVFS36W\n2JZX+bU5AgMBAAECggEAAl2pgN/hqF3271F8A/QWDXoS9hVar7p4iH/WGbA6FYS3\nvAp65JrhT8lHJRC7b/nesYas8ffsolIK0soUFd3PRqXYUeIf2gGJ1P+3DGVTXBwd\n909IOHYdY9Z1MkM7p0ZmniMYNHmmXbAPJ+q9d/FFhr5Jr4wiBsCNshcpcaYSoZ0r\nMkLMn0JLnYshqxt3kXd0hGi/h/psJsui0qwvgx0gIO8dnGkan+wcdqeGGqz2EraY\nZrpcRAgxrIgHb0I4QX9pbUs/oC/VGxLPbDL1rehxEW8Vq0qz2tqWoPKX4j+RJXQA\nETJPrLM6ZS59BiWMh/iSBy0EsHhO60RP6fMzdOdbjQKBgQD8SY7uTcFWZCA0cOKq\n/qV53VHEJIKTiI8RkTxnwaxbxROLMIrrhonz8WO5/BFbw65R7pSc8LoUNGkGGssF\nBPr6VlJJJXdF/XyDpks2d/9LjsgD3UA3r43NG7pSiEJi9qA4hxsaEbMh3rMki4kA\nsY0NjPal47VbqLslMduRJULkpQKBgQDCDzE9aWH+Y2bGMl8r+bt3kV/lDgLmL8fs\nhxQwfk+JCLjRQ6fOfxZUmPPyFmn8edN+1fq0KkjvGGR4tD7iHQFrsTB6NtTDBz4E\nUJ6B3LaKHPKsXTDJY39xYgF54JF5I9VUojGlNhrJ0JMEzuh5pmu4QRN751fihdXW\nbjAfnBPmBQKBgFucgnB6f7hVR3SDgWvCaGhmO6jT8S6NqhYg/SRYKbRxTfV/PRLl\nmfahMyt4Iv2FgylxTznmGEv59CEpXYuHEXQSIHM7TaJ2t94+ZpVy4ZuYT31HvGf8\nMavHY9NQc3roP6oHNYoz3y5vZfHhUXCVCLlg9LeshlCwZrTM9AQy2aWZAoGALhhL\nuumgRDu6OtPWNWzhcbpPS+ozGBg7ZdyEGCy4mbU/qT1ny632UOvv7g4S6MzLRvJu\n1YLBxkFGBEHUOgNnxfvVpwIFMbozqfS4YeJaXZ4YqoaMQxnmOLlt3lRQWbUARFUu\nc67RWCS590dqgxLbvW1/wkumXYEq1P9hYPDC7T0CgYAF6qJYjRV7gBeQO2vdT9YP\n2+6d7ApY/CTOUFp1vs5QbOTxr2BRfXeGruCuvBPSNuNhzfHEf0yM7tBhoaUWxefq\n/SJtBWiyLe2p/B6HJZ01NqsWwhCKnAhVSCaQDW+sEIqdKktzuwEU5UGdL2uDTtUF\nZ4rFJND0cxBglZmkx3ULWA==\n-----END PRIVATE KEY-----\n",
//       "client_email":
//           "support-app-messaging@altitude-support-capp-app.iam.gserviceaccount.com",
//       "client_id": "107866117364749390698",
//       "type": "service_account",
//     });

//     final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

//     final client = await clientViaServiceAccount(credentials, scopes);
//     return client.credentials.accessToken.data;
//   }

//   Future<void> sendPushNotification(String token, String roomId) async {
//     const fcmUrl =
//         "https://fcm.googleapis.com/v1/projects/altitude-support-capp-app/messages:send";

//     final accessToken = await getAccessToken();

//     final headers = {
//       "Content-Type": "application/json",
//       "Authorization": "Bearer $accessToken",
//     };

//     final body = {
//       "message": {
//         "token": token,
//         "notification": {
//           "title": "S.O.S Altitude",
//           "body": "O usuário $roomId está tentando realizar uma chamada.",
//         },
//         "data": {
//           "type": "new_call",
//           "room_id": roomId,
//           "client_name": roomId,
//           "call_type": widget.callPageType.name,
//         }
//       }
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(fcmUrl),
//         headers: headers,
//         body: jsonEncode(body),
//       );

//       log('Push notification response: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         log("Push notification enviada com sucesso!");
//       } else {
//         log("Erro ao enviar push notification: ${response.body}");
//       }
//     } catch (e) {
//       log("Erro ao enviar push notification: $e");
//     }
//   }

//   void _listenForCallStatus() {
//     log('Configurando listener para status da chamada...');
//     _callStatusSubscription?.cancel();
//     _callStatusSubscription = _supportDatabase
//         .ref("calls/$roomId/status")
//         .onValue
//         .listen((event) async {
//       if (!mounted) return;

//       final status = event.snapshot.value as String?;
//       log('Status da chamada alterado: $status');

//       if (status == "active") {
//         log('Chamada ativada - cancelando timer e iniciando duração');
//         _callingTimer?.cancel();
//         setState(() {
//           inCall = true;
//           isCalling = false;
//         });
//         _startCallDurationTimer();
//       } else if (status == "declined") {
//         log('Chamada recusada');
//         setState(() {
//           isDeclined = true;
//           isCalling = false;
//         });
//       } else if (status == "ended") {
//         log('Chamada encerrada - parando processo');
//         await _stopCallProcess(context: context, endCallRemotely: false);
//       }
//     });
//     log('Listener para status da chamada configurado');
//   }

//   Future<void> _startWebRTC() async {
//     try {
//       log('=== INICIANDO WEBRTC ===');

//       // Cria peer connection
//       log('Criando peer connection...');
//       _peerConnection = await createPeerConnection(_configuration);
//       log('Peer connection criada com sucesso');

//       // Configura event handlers
//       _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//         log('Connection state changed: $state');
//         if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
//             state ==
//                 RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
//           _handleConnectionError();
//         }
//       };

//       _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
//         log('ICE connection state changed: $state');
//         if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
//             state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
//           _handleConnectionError();
//         }
//       };

//       _peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//         log('ICE gathering state changed: $state');
//       };

//       _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
//         log('New ICE candidate: ${candidate.candidate}');
//         await _supportDatabase
//             .ref("calls/$roomId/ice_candidates/caller")
//             .push()
//             .set({
//           'candidate': candidate.candidate,
//           'sdpMid': candidate.sdpMid,
//           'sdpMLineIndex': candidate.sdpMLineIndex,
//         });
//       };

//       // Obtém stream de mídia
//       log('Obtendo stream de mídia...');
//       log('Tipo de chamada: ${widget.callPageType == CallPageType.video ? "vídeo" : "áudio"}');

//       _localStream = await navigator.mediaDevices.getUserMedia({
//         'audio': {
//           'echoCancellation': true,
//           'noiseSuppression': true,
//           'autoGainControl': true,
//           'channelCount': 1,
//           'sampleRate': 48000,
//         },
//         'video': widget.callPageType == CallPageType.video
//             ? {
//                 'width': {'ideal': 640},
//                 'height': {'ideal': 480},
//                 'facingMode': 'user',
//                 'frameRate': {'ideal': 30},
//               }
//             : false,
//       });

//       log('Stream de mídia obtido com sucesso');
//       log('Tracks no stream: ${_localStream?.getTracks().length}');
//       _localStream?.getTracks().forEach((track) {
//         log('Track: ${track.kind} - enabled: ${track.enabled}');
//       });

//       // Configura renderer local
//       log('Configurando renderer local...');
//       if (_localRenderer != null) {
//         _localRenderer!.srcObject = _localStream;
//         log('Renderer local configurado');
//       }

//       // Adiciona tracks ao peer connection
//       log('Adicionando tracks ao peer connection...');
//       _localStream?.getTracks().forEach((track) {
//         track.enabled = true;
//         _peerConnection?.addTrack(track, _localStream!);
//         log('Track ${track.kind} adicionada ao peer connection');
//       });

//       // Configura handler para stream remoto
//       _peerConnection?.onTrack = (RTCTrackEvent event) {
//         log('onTrack chamado - streams: ${event.streams.length}');
//         if (event.streams.isNotEmpty) {
//           log('Stream remoto recebido: ${event.streams[0].id}');
//           setState(() {
//             if (_remoteRenderer != null) {
//               _remoteRenderer!.srcObject = event.streams.first;
//               log('Stream remoto configurado no renderer');
//             }
//             inCall = true;
//           });
//         }
//       };

//       // Cria e envia offer
//       log('Criando offer...');
//       var offer = await _peerConnection?.createOffer();
//       await _peerConnection?.setLocalDescription(offer!);
//       await _supportDatabase.ref("calls/$roomId/offer").set({
//         'sdp': offer!.sdp,
//         'type': offer.type,
//       });

//       log('Offer criada e enviada');

//       // Escuta por answer e ICE candidates
//       log('Configurando listeners para answer e ICE candidates...');
//       _listenForAnswer();
//       _listenForIceCandidates("callee");

//       log('=== WEBRTC INICIADO COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO ao iniciar WebRTC: $e');
//       rethrow;
//     }
//   }

//   Future<void> _listenForAnswer() async {
//     log('Configurando listener para answer...');
//     _answerSubscription?.cancel();
//     _answerSubscription = _supportDatabase
//         .ref("calls/$roomId/answer")
//         .onValue
//         .listen((event) async {
//       if (!mounted) return;

//       if (event.snapshot.value != null) {
//         log('Answer recebida do suporte');
//         var answerData = event.snapshot.value as Map;
//         var answer =
//             RTCSessionDescription(answerData['sdp'], answerData['type']);

//         log('Configurando remote description...');
//         await _peerConnection?.setRemoteDescription(answer);
//         log('Remote description configurada');

//         setState(() {
//           inCall = true;
//         });
//         log('Estado da chamada atualizado para ativo');

//         log('Answer processada com sucesso');
//       }
//     });
//     log('Listener para answer configurado');
//   }

//   Future<void> _listenForIceCandidates(String receiver) async {
//     log('Configurando listener para ICE candidates do $receiver...');
//     _iceCandidatesSubscription?.cancel();
//     _iceCandidatesSubscription = _supportDatabase
//         .ref("calls/$roomId/ice_candidates/$receiver")
//         .onChildAdded
//         .listen((event) async {
//       if (!mounted) return;

//       if (event.snapshot.value != null) {
//         log('ICE candidate recebido do $receiver');
//         var candidateData = event.snapshot.value as Map;
//         var candidate = RTCIceCandidate(
//           candidateData['candidate'],
//           candidateData['sdpMid'],
//           candidateData['sdpMLineIndex'],
//         );

//         log('Adicionando ICE candidate ao peer connection...');
//         await _peerConnection?.addCandidate(candidate);
//         log('ICE candidate adicionado com sucesso');
//       }
//     });
//     log('Listener para ICE candidates do $receiver configurado');
//   }

//   void toggleMute() {
//     if (_localStream != null) {
//       var audioTrack = _localStream!.getAudioTracks().firstOrNull;
//       if (audioTrack != null) {
//         audioTrack.enabled = !audioTrack.enabled;
//         setState(() {
//           isMuted = !audioTrack.enabled;
//         });
//         log('Microfone ${audioTrack.enabled ? "ativado" : "desativado"}');
//       } else {
//         log('ERRO: Nenhuma track de áudio encontrada');
//       }
//     } else {
//       log('ERRO: Stream local não disponível');
//     }
//   }

//   void toggleCamera() {
//     if (_localStream != null && widget.callPageType == CallPageType.video) {
//       var videoTrack = _localStream!.getVideoTracks().firstOrNull;
//       if (videoTrack != null) {
//         videoTrack.enabled = !videoTrack.enabled;
//         setState(() {
//           isCameraOff = !videoTrack.enabled;
//         });
//         log('Câmera ${videoTrack.enabled ? "ativada" : "desativada"}');
//       } else {
//         log('ERRO: Nenhuma track de vídeo encontrada');
//       }
//     } else {
//       log('ERRO: Stream local não disponível ou não é chamada de vídeo');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isInitializing) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               const Text('Inicializando chamada...'),
//             ],
//           ),
//         ),
//       );
//     }

//     if (isError) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red, size: 48),
//               const SizedBox(height: 16),
//               Text(
//                 errorMessage,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 18),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _attemptReconnection,
//                 child: const Text('Tentar Reconectar'),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => _stopCallProcess(
//                   context: context,
//                   endCallRemotely: true,
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                 ),
//                 child: const Text('Encerrar Chamada'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (isDeclined) {
//       return _buildDeclinedScreen();
//     }

//     if (isCallEnded) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               const Text('Encerrando a chamada...'),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_remoteRenderer == null) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(height: 16),
//               const Text('Iniciando chamada...'),
//               if (isCalling) ...[
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Aguardando resposta...',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: widget.callPageType == CallPageType.video
//           ? _buildVideoCallWidget()
//           : _buildAudioCallWidget(),
//     );
//   }

//   Widget _buildDeclinedScreen() {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'O suporte não está disponível no momento.',
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 _cleanupResources();
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Tentar novamente'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 _stopCallProcess(context: context, endCallRemotely: true);
//               },
//               child: const Text('Cancelar'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoCallWidget() {
//     return Stack(
//       children: [
//         // Vídeo remoto (tela principal)
//         Container(
//           child: _remoteRenderer!.srcObject == null
//               ? Center(
//                   child: Column(
//                   mainAxisSize: MainAxisSize.max,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Chamando...'),
//                     Image.asset('assets/images/png/logo_altitude.png'),
//                   ],
//                 ))
//               : RTCVideoView(
//                   _remoteRenderer!,
//                   objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                 ),
//         ),

//         // Vídeo local (picture-in-picture)
//         if (_localRenderer != null && _localRenderer!.srcObject != null)
//           Positioned(
//             bottom: 40.0,
//             right: 40.0,
//             width: 120,
//             height: 160,
//             child: Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.white, width: 2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: RTCVideoView(
//                 _localRenderer!,
//                 mirror: true,
//                 objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//               ),
//             ),
//           ),

//         // Controles
//         Positioned(
//           bottom: 20,
//           left: 0,
//           right: 0,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // Botão mute
//               FloatingActionButton(
//                 onPressed: toggleMute,
//                 backgroundColor: isMuted ? Colors.red : Colors.grey,
//                 child: Icon(isMuted ? Icons.mic_off : Icons.mic),
//               ),

//               // Botão encerrar
//               FloatingActionButton(
//                 onPressed: () => _stopCallProcess(
//                   context: context,
//                   endCallRemotely: true,
//                 ),
//                 backgroundColor: Colors.red,
//                 child: const Icon(Icons.call_end),
//               ),

//               // Botão câmera
//               FloatingActionButton(
//                 onPressed: toggleCamera,
//                 backgroundColor: isCameraOff ? Colors.red : Colors.grey,
//                 child: Icon(isCameraOff ? Icons.videocam_off : Icons.videocam),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAudioCallWidget() {
//     return Stack(
//       children: [
//         // Conteúdo principal
//         Container(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _remoteRenderer!.srcObject == null
//                     ? const Text('Chamando...')
//                     : _buildTimerWidget(),
//                 Image.asset('assets/images/png/logo_altitude.png'),
//               ],
//             ),
//           ),
//         ),

//         // Controles
//         Positioned(
//           bottom: 20,
//           left: 0,
//           right: 0,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // Botão mute
//               FloatingActionButton(
//                 onPressed: toggleMute,
//                 backgroundColor: isMuted ? Colors.red : Colors.grey,
//                 child: Icon(isMuted ? Icons.mic_off : Icons.mic),
//               ),

//               // Botão encerrar
//               FloatingActionButton(
//                 onPressed: () => _stopCallProcess(
//                   context: context,
//                   endCallRemotely: true,
//                 ),
//                 backgroundColor: Colors.red,
//                 child: const Icon(Icons.call_end),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimerWidget() {
//     return ValueListenableBuilder<Duration>(
//       valueListenable: _callDuration,
//       builder: (context, duration, child) {
//         final minutes =
//             duration.inMinutes.remainder(60).toString().padLeft(2, '0');
//         final seconds =
//             duration.inSeconds.remainder(60).toString().padLeft(2, '0');
//         return Text(
//           '$minutes:$seconds',
//           style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//         );
//       },
//     );
//   }

//   Future<void> _stopCallProcess({
//     bool endCallRemotely = false,
//     required BuildContext context,
//   }) async {
//     if (isStoppingCall) return;

//     try {
//       log('=== ENCERRANDO PROCESSO DE CHAMADA ===');
//       log('endCallRemotely: $endCallRemotely');

//       if (!mounted) return;

//       setState(() {
//         isStoppingCall = true;
//         isCallEnded = true;
//       });

//       if (endCallRemotely) {
//         log('Atualizando status da chamada para "ended"...');
//         await _supportDatabase.ref('calls/$roomId/status').set("ended");
//         log('Status da chamada atualizado');
//       }

//       log('Limpando recursos...');
//       await _cleanupResources();

//       // Remove dados da chamada do Firebase
//       log('Removendo dados da chamada do Firebase...');
//       await _supportDatabase.ref("calls/$roomId").remove();
//       log('Dados da chamada removidos');

//       if (mounted) {
//         log('Navegando para a tela inicial...');
//         navigatorKey.currentState?.pushAndRemoveUntil(
//           MaterialPageRoute(
//             builder: (context) => const IpdHomePage(),
//           ),
//           (route) => false,
//         );
//         log('Navegação concluída');
//       }

//       log('=== PROCESSO DE CHAMADA ENCERRADO COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO ao encerrar processo de chamada: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           isStoppingCall = false;
//         });
//       }
//     }
//   }

//   void _handleConnectionError() {
//     if (!mounted) return;

//     log('=== ERRO DE CONEXÃO DETECTADO ===');
//     log('Tentando reconexão...');

//     setState(() {
//       isError = true;
//       errorMessage = 'Erro na conexão. Tentando reconectar...';
//     });

//     _attemptReconnection();
//   }

//   Future<void> _attemptReconnection() async {
//     try {
//       log('=== TENTANDO RECONEXÃO ===');

//       setState(() {
//         isError = false;
//         errorMessage = '';
//       });

//       log('Limpando recursos para reconexão...');
//       await _cleanupResources();

//       log('Aguardando 2 segundos antes de reconectar...');
//       await Future.delayed(const Duration(seconds: 2));

//       log('Iniciando WebRTC para reconexão...');
//       await _startWebRTC();

//       log('=== RECONEXÃO REALIZADA COM SUCESSO ===');
//     } catch (e) {
//       log('ERRO na reconexão: $e');
//       if (mounted) {
//         setState(() {
//           isError = true;
//           errorMessage = 'Falha na reconexão. Por favor, tente novamente.';
//         });
//       }
//     }
//   }
// }
