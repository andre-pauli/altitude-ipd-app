# Guia de Teste - Integração IPD e Support App

Este documento descreve como testar a integração entre o IPD App e o Support Call App.

## 🧪 Pré-requisitos para Teste

### Hardware Necessário
- 2 dispositivos Android (ou 1 dispositivo + 1 emulador)
- Conexão com internet
- Câmera e microfone funcionais

### Software Necessário
- Flutter SDK 3.0.0+
- Android Studio / VS Code
- Firebase CLI (opcional)

## 🚀 Configuração Inicial

### 1. Configurar Firebase
```bash
# Verificar se o Firebase está configurado
cd altitude-ipd-app
flutter pub get

cd ../altitude_support_call_app
flutter pub get
```

### 2. Verificar Configurações
- [ ] Firebase configurado corretamente
- [ ] WebRTC servidor acessível
- [ ] Telegram bot configurado
- [ ] Permissões de câmera/microfone

## 📱 Teste do IPD App

### 1. Teste Básico
```bash
cd altitude-ipd-app
flutter run
```

**Verificar:**
- [ ] App inicia sem erros
- [ ] Interface carrega corretamente
- [ ] Botões respondem ao toque
- [ ] Firebase conecta

### 2. Teste do Botão SOS
1. Pressione o botão "SOS"
2. Confirme a ação
3. Selecione tipo de chamada

**Verificar:**
- [ ] Dialog de confirmação aparece
- [ ] Dialog de seleção de tipo aparece
- [ ] Navegação para página de chamada funciona

### 3. Teste de Chamada
1. Selecione "Chamada de Voz" ou "Chamada de Vídeo"
2. Aguarde inicialização

**Verificar:**
- [ ] Permissões são solicitadas
- [ ] Firebase cria sala
- [ ] WebRTC inicializa
- [ ] Interface de chamada carrega

## 📱 Teste do Support App

### 1. Teste Básico
```bash
cd altitude_support_call_app
flutter run
```

**Verificar:**
- [ ] App inicia sem erros
- [ ] Firebase conecta
- [ ] Interface carrega

### 2. Teste de Notificação
1. Inicie uma chamada no IPD
2. Verifique se notificação chega no Support App

**Verificar:**
- [ ] Notificação push recebida
- [ ] CallKit mostra interface de chamada
- [ ] Botões de aceitar/recusar funcionam

### 3. Teste de Chamada
1. Aceite a chamada no Support App
2. Verifique conexão WebRTC

**Verificar:**
- [ ] WebRTC conecta
- [ ] Áudio/vídeo funcionam
- [ ] Interface de chamada carrega
- [ ] Controles funcionam

## 🔄 Teste de Integração Completa

### Cenário 1: Chamada de Voz
1. **IPD**: Pressione SOS → Chamada de Voz
2. **Support**: Receba notificação → Aceite chamada
3. **Verificar**: Áudio funciona em ambas as direções

### Cenário 2: Chamada de Vídeo
1. **IPD**: Pressione SOS → Chamada de Vídeo
2. **Support**: Receba notificação → Aceite chamada
3. **Verificar**: Áudio e vídeo funcionam

### Cenário 3: Notificação Apenas
1. **IPD**: Pressione SOS → Apenas Notificar
2. **Verificar**: Mensagem Telegram enviada

### Cenário 4: Chamada Recusada
1. **IPD**: Inicie chamada
2. **Support**: Recuse chamada
3. **Verificar**: IPD mostra mensagem de recusa

## 🐛 Troubleshooting

### Problema: Firebase não conecta
**Solução:**
- Verificar configuração do google-services.json
- Verificar conectividade com internet
- Verificar regras do Firebase Database

### Problema: WebRTC não conecta
**Solução:**
- Verificar servidor de sinalização
- Verificar permissões de câmera/microfone
- Verificar STUN servers

### Problema: Notificações não chegam
**Solução:**
- Verificar configuração FCM
- Verificar tokens salvos no Firebase
- Verificar permissões de notificação

### Problema: Chamadas não estabelecem
**Solução:**
- Verificar logs do Firebase
- Verificar logs do WebRTC
- Verificar configuração ICE servers

## 📊 Logs para Verificar

### IPD App
```bash
flutter logs
# Procurar por:
# - Firebase connection
# - WebRTC initialization
# - Call status changes
```

### Support App
```bash
flutter logs
# Procurar por:
# - FCM notifications
# - Call acceptance
# - WebRTC connection
```

### Firebase Console
- Realtime Database: Verificar dados de chamadas
- Analytics: Verificar eventos
- Crashlytics: Verificar erros

## ✅ Checklist de Teste

### Funcionalidades IPD
- [ ] Interface carrega
- [ ] Botão SOS funciona
- [ ] Seleção de tipo de chamada
- [ ] Permissões solicitadas
- [ ] Firebase conecta
- [ ] WebRTC inicializa
- [ ] Interface de chamada
- [ ] Controles de chamada
- [ ] Encerramento de chamada

### Funcionalidades Support
- [ ] App inicia
- [ ] Firebase conecta
- [ ] Notificações recebidas
- [ ] CallKit funciona
- [ ] Aceitar chamadas
- [ ] Recusar chamadas
- [ ] Interface de chamada
- [ ] WebRTC conecta
- [ ] Áudio/vídeo funcionam

### Integração
- [ ] Chamadas estabelecem
- [ ] Dados sincronizam
- [ ] Status atualiza
- [ ] Notificações funcionam
- [ ] Logs registram eventos

## 🎯 Próximos Passos

Após testes bem-sucedidos:
1. Configurar produção
2. Implementar monitoramento
3. Configurar alertas
4. Documentar procedimentos
5. Treinar usuários

## 📞 Suporte

Em caso de problemas:
1. Verificar logs
2. Consultar documentação
3. Contatar equipe técnica
4. Abrir issue no repositório 