import 'package:altitude_ipd_app/src/ui/_core/image_path_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BannerInformationWidget extends StatelessWidget {
  const BannerInformationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;
    return Column(
      children: [
        Row(
          children: [
            _buildInfoCard(
              title: 'Capacidade',
              content: '8 Pessoas',
              width: widthRatio,
              height: heightRatio,
              assetName: ImagePathConstants.iconPeople,
            ),
            SizedBox(
              width: 17.0 * widthRatio,
            ),
            _buildInfoCard(
              title: 'Carga',
              content: '600 KG',
              width: widthRatio,
              height: heightRatio,
              assetName: ImagePathConstants.iconWeight,
            ),
            SizedBox(
              width: 17.0 * widthRatio,
            ),
            _buildWeatherInfoCard(
              width: widthRatio,
              height: heightRatio,
            ),
          ],
        ),
        SizedBox(
          height: 32 * heightRatio,
        ),
        _buildStatusCard(width: widthRatio, height: heightRatio)
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required double width,
    required double height,
    required String assetName,
  }) {
    return Container(
      width: 200 * width,
      height: 300 * height,
      decoration: BoxDecoration(
        color: const Color(0xFF414042),
        borderRadius: BorderRadius.circular(16.0 * width),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36 * width,
            ),
          ),
          SvgPicture.asset(
            assetName,
            height: 102.58 * height,
          ),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 38.16 * width,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required double width,
    required double height,
  }) {
    return Container(
      width: 635 * width,
      height: 296 * height,
      padding: EdgeInsets.symmetric(horizontal: 32 * width),
      decoration: BoxDecoration(
        color: const Color(0xFF414042),
        borderRadius: BorderRadius.circular(16.0 * width),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * width,
            ),
          ),
          Text(
            'Elevador em movimento, mantenha-se afastado(a) da porta.',
            style: TextStyle(
                color: Colors.white,
                fontSize: 40 * width,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoCard({
    required double width,
    required double height,
  }) {
    return Container(
      width: 200 * width,
      height: 300 * height,
      padding:
          EdgeInsets.symmetric(horizontal: 24 * width, vertical: 5 * height),
      decoration: BoxDecoration(
        color: const Color.fromARGB(08, 255, 255, 255),
        borderRadius: BorderRadius.circular(16.0 * width),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SvgPicture.asset(
            ImagePathConstants.iconWeather,
            height: 49.44 * height,
          ),
          Text(
            '24°',
            style: TextStyle(fontSize: 80 * width, color: Colors.white),
          ),
          Text(
            'São Paulo',
            style: TextStyle(
                fontSize: 28 * width,
                color: Colors.white,
                fontWeight: FontWeight.w500),
          ),
          Text(
            'Parcialmente nublado',
            style: TextStyle(fontSize: 24 * width, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
