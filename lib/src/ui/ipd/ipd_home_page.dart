import 'package:altitude_ipd_app/src/ui/_core/image_path_constants.dart';
import 'package:altitude_ipd_app/src/ui/ipd/ipd_home_controller.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/andar_indicator_card.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/banner_information_widget.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/custom_button.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/number_buttons_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class IpdHomePage extends StatefulWidget {
  const IpdHomePage({super.key});

  @override
  State<IpdHomePage> createState() => _IpdHomePageState();
}

class _IpdHomePageState extends State<IpdHomePage> {
  final IpdHomeController controller = IpdHomeController();
  bool showKeyboard = true;

  @override
  void initState() {
    super.initState();
    controller.onUpdate = () {
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
                  andarAtual: controller.andarAtual.toString(),
                ),
                SizedBox(
                  width: 32.0 * widthRatio,
                ),
                const BannerInformationWidget(),
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
                  icon: ImagePathConstants.iconKeyboard,
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
                  icon: ImagePathConstants.iconEmergency,
                  backgroundColor: Colors.red,
                  onPressed: () {},
                  width: 280 * widthRatio,
                  height: 108 * heightRatio,
                  heightIcon: 37.47 * heightRatio,
                  textStyle:
                      TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
                ),
                CustomButton(
                  label: 'Ajustes',
                  icon: ImagePathConstants.iconSettings,
                  backgroundColor: Colors.grey[800]!,
                  onPressed: () {},
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
                SizedBox(
                  width: 268.3 * widthRatio,
                  height: 107.89 * heightRatio,
                  child: SvgPicture.asset(ImagePathConstants.altitudeLogo),
                ),
                Text('1.0.0',
                    style: TextStyle(
                        color: Colors.white, fontSize: 28.0 * widthRatio)),
                Text('Ultima revisão: 10/11/2024',
                    style: TextStyle(
                        color: Colors.white, fontSize: 28.0 * widthRatio)),
              ],
            )
          ],
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
          color: Colors.blue,
        ),
        SizedBox(
          height: 18.0 * heightRatio,
        ),
        Container(
          width: 1080 * widthRatio,
          height: 302 * heightRatio,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _showKeyboard(double widthRatio, double heightRatio) {
    return Container(
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
              numberOfButtons: 4,
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
            onPressed: () {},
            width: 806 * widthRatio,
            height: 96 * heightRatio,
            textStyle:
                TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
          )
        ],
      ),
    );
  }
}