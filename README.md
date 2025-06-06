# IPD Altitude App

Aplicativo Flutter para comunicação serial e gerenciamento de dados em dispositivos Android.

## Funcionalidades

- Comunicação serial bidirecional via porta ttyS0
- Processamento de mensagens JSON
- Gerenciamento de buffer para dados recebidos
- Integração com Firebase (Auth, Database, Messaging)
- Suporte a WebRTC para comunicação em tempo real
- Reprodução de vídeo
- Carrossel de imagens
- Localização do dispositivo
- Permissões de sistema configuradas

## Requisitos

- Flutter SDK >= 3.0.0
- Android Studio
- Dispositivo Android com porta serial

## Dependências Principais

- flutter_svg: ^2.0.14
- http: ^1.3.0
- location: ^7.0.1
- webview_flutter: ^4.10.0
- permission_handler: ^11.3.1
- socket_io_client: ^3.0.2
- flutter_webrtc: ^0.12.2
- firebase_core: ^3.10.1
- firebase_auth: ^5.4.1
- firebase_database: ^11.3.1
- firebase_messaging: ^15.2.1

## Configuração

1. Clone o repositório
2. Execute `flutter pub get` para instalar as dependências
3. Configure as credenciais do Firebase
4. Execute o aplicativo com `flutter run`

## Estrutura do Projeto

- `android/app/src/main/kotlin/` - Código nativo Android para comunicação serial
- `assets/` - Recursos do aplicativo (imagens, vídeos, fontes)
- `lib/` - Código Flutter

## Permissões Android

O aplicativo requer várias permissões para funcionar corretamente:

- Acesso à localização
- Internet
- Armazenamento
- Bluetooth
- Câmera
- Áudio
- Wake Lock
- E outras permissões de sistema

## Licença

Este projeto é proprietário e confidencial.
