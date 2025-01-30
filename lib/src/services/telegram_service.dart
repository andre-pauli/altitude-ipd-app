import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  final String botToken = "7819105841:AAHH_FehkoavVorcUp_AkkWRCmklPNvcSik";
  final String chatId = "-4708090583";

  Future<void> sendMessage(String message) async {
    final url = Uri.parse("https://api.telegram.org/bot$botToken/sendMessage");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chat_id": chatId,
          "text": message,
        }),
      );

      if (response.statusCode == 200) {
        print("Mensagem enviada com sucesso!");
      } else {
        print("Erro ao enviar mensagem: ${response.body}");
      }
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
    }
  }
}
