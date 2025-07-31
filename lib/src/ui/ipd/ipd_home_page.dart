import 'package:altitude_ipd_app/src/services/telegram_service.dart';
import 'package:altitude_ipd_app/src/ui/_core/image_path_constants.dart';
import 'package:altitude_ipd_app/src/ui/_core/enumerators.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/andar_indicator_card.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/banner_information_widget.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/custom_button.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/image_carousel_widget.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/looping_video_player.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/number_buttons_widget.dart';
import 'package:altitude_ipd_app/src/ui/call_page/call_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

class IpdHomePage extends StatefulWidget {
  const IpdHomePage({super.key});

  @override
  State<IpdHomePage> createState() => _IpdHomePageState();
}

class _IpdHomePageState extends State<IpdHomePage> with WidgetsBindingObserver {
  final IpdHomeController controller = IpdHomeController();

  bool showKeyboard = false;
  int andarSelecionado = 0;
  String version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fakePopulateFields();
    controller.onUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.enviarComandoBooleano(
          acao: "buscar_dados_iniciais", estado: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a refresh when the app resumes
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 60.0 * widthRatio, vertical: 60.0 * heightRatio),
        child: Column(
          children: [
            Row(
              children: [
                AndarIndicatorCard(
                  andarAtual: controller
                      .andares[controller.andarAtual.toString()]?['andar'],
                  description: controller
                      .andares[controller.andarAtual.toString()]?['descricao'],
                ),
                SizedBox(
                  width: 32.0 * widthRatio,
                ),
                BannerInformationWidget(
                  capacidadeMaximaKg: controller.capacidadeMaximaKg ?? 0,
                  capacidadePessoas: controller.capacidadePessoas ?? 0,
                  latitude: controller.latitude ?? 0,
                  longitude: controller.longitude ?? 0,
                  mensagens: controller.mensagens ?? [],
                ),
              ],
            ),
            SizedBox(
              height: 50.0 * heightRatio,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomButton(
                  label: 'Selecionar andar',
                  iconPath: ImagePathConstants.iconKeyboard,
                  backgroundColor: Colors.grey[800]!,
                  onPressed: () {
                    setState(() {
                      showKeyboard = !showKeyboard;
                    });
                  },
                  width: 414 * widthRatio,
                  height: 108 * heightRatio,
                  heightIcon: 28 * heightRatio,
                  textStyle:
                      TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
                ),
                CustomButton(
                  label: 'SOS',
                  iconPath: ImagePathConstants.iconEmergency,
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirmar SOS'),
                          content: Text(
                              'Deseja realmente entrar em contato com o suporte?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Não'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showCallTypeSelection();
                              },
                              child: Text('Sim'),
                            ),
                          ],
                        );
                      },
                    );

                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => SelectCallTypePage(
                    //       roomId: controller.nomeObra ?? '-',
                    //       mensagens: controller.mensagens ?? [],
                    //     ),
                    //   ),
                    // );
                  },
                  width: 280 * widthRatio,
                  height: 108 * heightRatio,
                  heightIcon: 37.47 * heightRatio,
                  textStyle:
                      TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
                ),
                CustomButton(
                  label: 'Abrir porta',
                  backgroundColor: Colors.grey[800]!,
                  onPressed: () {
                    controller.enviarComandoBooleano(
                        acao: "abrir_porta_automatica", estado: true);
                  },
                  width: 280 * widthRatio,
                  height: 108 * heightRatio,
                  heightIcon: 42 * heightRatio,
                  textStyle:
                      TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
                ),
              ],
            ),
            SizedBox(
              height: 56.0 * heightRatio,
            ),
            showKeyboard
                ? _showKeyboard(widthRatio, heightRatio)
                : _showPublicityCard(widthRatio, heightRatio),
            SizedBox(
              height: 40.0 * heightRatio,
            ),
            const Divider(
              height: 0,
            ),
            SizedBox(
              height: 42.0 * heightRatio,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onLongPress: () async {},
                  child: SizedBox(
                    width: 268.3 * widthRatio,
                    height: 107.89 * heightRatio,
                    child: SvgPicture.asset(ImagePathConstants.altitudeLogo),
                  ),
                ),
                Column(
                  children: [
                    Text(version.isEmpty ? '' : version,
                        style: TextStyle(
                            color: Colors.white, fontSize: 28.0 * widthRatio)),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Text('SAC 17-98215-9000',
                        style: TextStyle(
                            color: Colors.white, fontSize: 28.0 * widthRatio)),
                  ],
                ),
                Text(
                    'Ultima manutenção: \n${controller.dataUltimaManutencao ?? '-'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontSize: 28.0 * widthRatio)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _fakePopulateFields() async {
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      version = packageInfo.version;
      controller.capacidadeMaximaKg = 320;
      controller.capacidadePessoas = 4;
    });
  }

  Future<void> _sendMessageTelegram() async {
    TelegramService _telegramService = TelegramService();
    await _telegramService.sendMessage(
        "O cliente ${controller.nomeObra} fez um chamado pro S.O.S \n Ele está com os seguintes erros: \n ${controller.mensagens?.join('\n') ?? ''}");
  }

  void _showCallTypeSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tipo de Chamada'),
          content: const Text('Selecione o tipo de chamada:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startCall(CallPageType.audio);
              },
              child: const Text('Chamada de Voz'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startCall(CallPageType.video);
              },
              child: const Text('Chamada de Vídeo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendMessageTelegram();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Suporte Contatado'),
                      content: const Text(
                          'O suporte foi notificado e logo fará o contato.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Apenas Notificar'),
            ),
          ],
        );
      },
    );
  }

  void _startCall(CallPageType callType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallPage(
          callPageType: callType,
          roomId: controller.nomeObra ??
              'Elevador-${DateTime.now().millisecondsSinceEpoch}',
          mensagens: controller.mensagens ?? [],
        ),
      ),
    );
  }

  Widget _showPublicityCard(double widthRatio, double heightRatio) {
    return Column(
      children: [
        Container(
          width: 1080 * widthRatio,
          height: 445 * heightRatio,
          child:
              LoopingVideoPlayer(videoPath: 'assets/videos/video_altitude.mp4'),
        ),
        SizedBox(
          height: 18.0 * heightRatio,
        ),
        ImageCarousel(widthRatio: widthRatio, heightRatio: heightRatio)
      ],
    );
  }

  Widget _showKeyboard(double widthRatio, double heightRatio) {
    return Stack(
      children: [
        Container(
          height: 766 * heightRatio,
          width: 1080 * widthRatio,
          padding: EdgeInsets.symmetric(
              horizontal: 137.0 * widthRatio, vertical: 68.0 * heightRatio),
          decoration: BoxDecoration(
            color: const Color.fromARGB(08, 255, 255, 255),
            borderRadius: BorderRadius.circular(16.0 * widthRatio),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 476 * heightRatio,
                width: 1080 * widthRatio,
                child: NumbersButtonsWidget(
                  andares: controller.andares,
                  selectAndar: (andarDestino) {
                    andarSelecionado = andarDestino;
                  },
                  width: widthRatio,
                  height: heightRatio,
                ),
              ),
              SizedBox(
                height: 58.0 * heightRatio,
              ),
              CustomButton(
                label: 'Confirmar',
                backgroundColor: Colors.grey[800]!,
                onPressed: () {
                  if (andarSelecionado != 0) {
                    controller.enviarComandoIrParaAndar(andarSelecionado);
                    setState(() {
                      showKeyboard = !showKeyboard;
                    });
                  }
                },
                width: 806 * widthRatio,
                height: 96 * heightRatio,
                textStyle:
                    TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
              )
            ],
          ),
        ),
        Positioned(
          right: widthRatio * 32.0,
          top: heightRatio * 32.0,
          child: IconButton(
            onPressed: () {
              setState(() {
                showKeyboard = !showKeyboard;
              });
            },
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: widthRatio * 60.0,
            ),
          ),
        ),
      ],
    );
  }
}
