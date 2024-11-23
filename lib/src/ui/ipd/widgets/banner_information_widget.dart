import 'dart:async';

import 'package:altitude_ipd_app/services/location_service.dart';
import 'package:altitude_ipd_app/services/weather_service.dart';
import 'package:altitude_ipd_app/src/ui/_core/image_path_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// ignore: must_be_immutable
class BannerInformationWidget extends StatefulWidget {
  int capacidadeMaximaKg = 0;
  int capacidadePessoas = 0;
  List<String> mensagens = [];

  BannerInformationWidget(
      {super.key,
      required this.capacidadeMaximaKg,
      required this.capacidadePessoas, required this.mensagens});

  @override
  State<BannerInformationWidget> createState() =>
      _BannerInformationWidgetState();
}

class _BannerInformationWidgetState extends State<BannerInformationWidget> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  Map<String, dynamic>? weatherData;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void fetchWeatherData() async {
    try {
      final position = await _locationService.getCurrentLocation();
      final data = await _weatherService.fetchWeatherByCoordinates(
          position.latitude, position.longitude);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print("Erro ao carregar os dados: $e");
    }
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) {
      fetchWeatherData();
    });
  }

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
              content: '${widget.capacidadePessoas} Pessoas',
              width: widthRatio,
              height: heightRatio,
              assetName: ImagePathConstants.iconPeople,
            ),
            SizedBox(
              width: 17.0 * widthRatio,
            ),
            _buildInfoCard(
              title: 'Carga',
              content: '${widget.capacidadeMaximaKg.toStringAsFixed(1)} KG',
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
        _buildStatusCard(width: widthRatio, height: heightRatio, mensagens: widget.mensagens)
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
    List<String> mensagens = const [],
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
            mensagens.isNotEmpty ? mensagens.join('\n') : 'Pronto pra uso.',
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
      child: weatherData == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 16),
                Text(
                  'Carregando dados do clima...',
                  style: TextStyle(color: Colors.white),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SvgPicture.asset(
                  ImagePathConstants.iconWeather,
                  height: 49.44 * height,
                ),
                Text(
                  '${weatherData!['main']['temp']}°',
                  style: TextStyle(fontSize: 50 * width, color: Colors.white),
                ),
                Text(
                  weatherData!['name'],
                  style: TextStyle(
                      fontSize: 28 * width,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  weatherData!['weather'][0]['description'],
                  style: TextStyle(fontSize: 24 * width, color: Colors.white),
                ),
              ],
            ),
    );
  }
}
