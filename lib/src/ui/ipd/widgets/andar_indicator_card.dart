import 'package:flutter/material.dart';

// ignore: must_be_immutable
class AndarIndicatorCard extends StatelessWidget {
  final int andarAtual;
  final Map<String, dynamic> andares;

  const AndarIndicatorCard({
    super.key,
    required this.andarAtual,
    required this.andares,
  });

  String get _andarDisplay {
    // Se não temos dados dos andares ainda, mostra "Carregando..."
    if (andares.isEmpty) {
      return "...";
    }

    // Busca o andar no mapa de andares
    // Estrutura do Python: {1: {"andar": "0", "descricao": "Térreo"}, 2: {"andar": "1", "descricao": "1º Andar"}}
    // Precisamos encontrar o índice que contém o andar atual
    for (final entry in andares.entries) {
      final andarInfo = entry.value;
      if (andarInfo is Map<String, dynamic> &&
          andarInfo['andar'] != null &&
          andarInfo['andar'].toString() == andarAtual.toString()) {
        return andarInfo['andar'].toString();
      }
    }

    // Fallback: se não encontrar, usa o andar atual diretamente
    return andarAtual.toString();
  }

  String get _description {
    // Se não temos dados dos andares ainda, mostra "Carregando..."
    if (andares.isEmpty) {
      return "Carregando...";
    }

    // Busca a descrição no mapa de andares
    // Estrutura do Python: {1: {"andar": "0", "descricao": "Térreo"}, 2: {"andar": "1", "descricao": "1º Andar"}}
    // Precisamos encontrar o índice que contém o andar atual
    for (final entry in andares.entries) {
      final andarInfo = entry.value;
      if (andarInfo is Map<String, dynamic> &&
          andarInfo['andar'] != null &&
          andarInfo['andar'].toString() == andarAtual.toString()) {
        return andarInfo['descricao']?.toString() ?? "Andar $andarAtual";
      }
    }

    // Fallback: descrição padrão baseada no andar
    if (andarAtual == 0) return "Térreo";
    if (andarAtual == 1) return "1º Andar";
    if (andarAtual == 2) return "2º Andar";
    if (andarAtual == 3) return "3º Andar";
    if (andarAtual == 4) return "4º Andar";
    if (andarAtual == 5) return "5º Andar";

    return "Andar $andarAtual";
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;

    return Container(
      width: 413 * widthRatio,
      height: 628 * heightRatio,
      padding: EdgeInsets.symmetric(vertical: 32.05 * heightRatio),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _description,
            style: TextStyle(
                color: Colors.white,
                fontSize: 42.73 * widthRatio,
                fontWeight: FontWeight.w500),
          ),
          Text(
            _andarDisplay,
            style: TextStyle(
              color: Colors.white,
              fontSize: 340 * heightRatio,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
