import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey =
      "3b5f158ce6139961df47c7579f9f1629"; // Substitua com sua chave da API
  final String baseUrl = "https://api.openweathermap.org/data/2.5/weather";

  Future<Map<String, dynamic>> fetchWeatherByCoordinates(
      double latitude, double longitude) async {
    log('$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=pt');
    final url = Uri.parse(
        '$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric&lang=pt');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar dados do clima');
    }
  }
}
