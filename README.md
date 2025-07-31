# Altitude IPD App - Sistema Integrado de Elevador e Suporte

Este projeto consiste em dois aplicativos Flutter integrados para fornecer um sistema completo de monitoramento e suporte para elevadores.

## 📱 Aplicativos

### 1. IPD App (`altitude-ipd-app`)
- **Função**: Interface do usuário no elevador
- **Recursos**:
  - Controle de andares
  - Monitoramento de status
  - Botão SOS para chamadas de emergência
  - Integração com WebRTC para chamadas de voz/vídeo
  - Notificações via Telegram
  - Interface responsiva para telas touch

### 2. Support Call App (`altitude_support_call_app`)
- **Função**: Aplicativo de suporte para técnicos
- **Recursos**:
  - Recebimento de chamadas de emergência
  - Interface de chamadas WebRTC
  - Notificações push via Firebase
  - Monitoramento de status dos elevadores
  - Sistema de autenticação

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.0.0 ou superior
- Android Studio / VS Code
- Dispositivo Android ou emulador

### IPD App
```bash
cd altitude-ipd-app
flutter pub get
flutter run
```

### Support Call App
```bash
cd altitude_support_call_app
flutter pub get
flutter run
```

## 🔧 Configuração

### Firebase
Ambos os aplicativos usam Firebase para:
- **Realtime Database**: Sincronização de status e chamadas
- **Firebase Messaging**: Notificações push
- **Firebase Auth**: Autenticação (app de suporte)

### WebRTC
- **Servidor de Sinalização**: `http://91.108.125.86:3000`
- **STUN Servers**: Google STUN servers
- **Funcionalidades**: Chamadas de voz e vídeo

### Telegram
- **Bot Token**: Configurado no `TelegramService`
- **Chat ID**: Grupo de suporte
- **Função**: Notificações de emergência

## 📋 Fluxo de Funcionamento

### 1. Usuário no Elevador
1. Usuário pressiona botão SOS
2. Seleciona tipo de chamada (voz/vídeo/notificação)
3. Sistema inicia chamada WebRTC ou envia notificação

### 2. Sistema de Chamadas
1. IPD cria sala no Firebase
2. Envia notificação push para app de suporte
3. App de suporte recebe notificação
4. Técnico aceita chamada
5. WebRTC estabelece conexão

### 3. Monitoramento
- Status do elevador sincronizado via Firebase
- Logs de eventos salvos no banco
- Notificações automáticas para problemas

## 🛠️ Estrutura do Projeto

### IPD App
```
lib/
├── main.dart
├── src/
│   ├── services/
│   │   ├── signaling_service.dart
│   │   ├── telegram_service.dart
│   │   └── weather_service.dart
│   └── ui/
│       ├── _core/
│       ├── call_page/
│       └── ipd/
```

### Support Call App
```
lib/
├── main.dart
├── core/
├── features/
│   ├── rescue/
│   └── support/
```

## 🔌 Integração

### Comunicação entre Apps
- **Firebase Realtime Database**: Sincronização de dados
- **Firebase Messaging**: Notificações push
- **WebRTC**: Chamadas de voz/vídeo
- **Socket.IO**: Sinalização WebRTC

### Dados Compartilhados
- Status do elevador
- Informações de chamadas
- Logs de eventos
- Configurações do sistema

## 📱 Funcionalidades Principais

### IPD App
- ✅ Interface de controle de andares
- ✅ Botão SOS integrado
- ✅ Chamadas WebRTC (voz/vídeo)
- ✅ Notificações Telegram
- ✅ Monitoramento de status
- ✅ Interface responsiva

### Support Call App
- ✅ Recebimento de chamadas
- ✅ Interface de chamadas WebRTC
- ✅ Notificações push
- ✅ Monitoramento de elevadores
- ✅ Sistema de autenticação

## 🐛 Troubleshooting

### Problemas Comuns
1. **Chamadas não conectam**: Verificar servidor de sinalização
2. **Notificações não chegam**: Verificar configuração Firebase
3. **WebRTC não funciona**: Verificar permissões de câmera/microfone

### Logs
- Logs detalhados no console
- Firebase Analytics para monitoramento
- Telegram para notificações críticas

## 📄 Licença

Este projeto é proprietário da Altitude Elevadores.

## 👥 Suporte

Para suporte técnico, entre em contato com a equipe de desenvolvimento.
