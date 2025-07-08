import 'package:altitude_ipd_app/src/ui/_core/enumerators.dart';
import 'package:altitude_ipd_app/src/ui/ipd/widgets/custom_button.dart';
import 'package:altitude_ipd_app/src/ui/call_page/call_page.dart';
import 'package:flutter/material.dart';

class SelectCallTypePage extends StatelessWidget {
  final String roomId;
  final List<String> mensagens;
  SelectCallTypePage({
    super.key,
    required this.roomId,
    required this.mensagens,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            CustomButton(
              label: 'Áudio',
              icon: Icon(
                Icons.phone,
                color: Colors.white,
              ),
              backgroundColor: Colors.grey[800]!,
              onPressed: () async {
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => CallPage(
                //       callPageType: CallPageType.audio,
                //       roomId: roomId,
                //       mensagens: mensagens,
                //     ),
                //   ),
                // );
              },
              width: 500 * widthRatio,
              height: 108 * heightRatio,
              heightIcon: 37.47 * heightRatio,
              textStyle:
                  TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
            ),
            const SizedBox(
              height: 30,
            ),
            CustomButton(
              label: 'Vídeo',
              icon: Icon(
                Icons.video_camera_front,
                color: Colors.white,
              ),
              backgroundColor: Colors.grey[800]!,
              onPressed: () async {
                // Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => CallPage(
                //       callPageType: CallPageType.video,
                //       roomId: roomId,
                //       mensagens: mensagens,
                //     ),
                //   ),
                // );
              },
              width: 500 * widthRatio,
              height: 108 * heightRatio,
              heightIcon: 37.47 * heightRatio,
              textStyle:
                  TextStyle(color: Colors.white, fontSize: 40 * widthRatio),
            ),
          ],
        ),
      ),
    );
  }
}
