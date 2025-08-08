# Integração WebSocket - Altitude IPD App

## Visão Geral

Esta implementação adiciona comunicação WebSocket como alternativa à comunicação RS485 existente. A funcionalidade permite escolher entre os dois modos de comunicação sem remover a funcionalidade existente.

## Características

- ✅ **Comunicação WebSocket**: Nova opção de comunicação via WiFi
- ✅ **Comunicação RS485**: Mantida como opção padrão
- ✅ **Seleção de Modo**: Interface para escolher entre RS485 e WebSocket
- ✅ **Reconexão Automática**: WebSocket reconecta automaticamente em caso de falha
- ✅ **Funciona sem Internet**: Comunicação local via rede WiFi

## Estrutura dos Projetos

### App Flutter (`altitude-ipd-app`)

#### Novos Arquivos:
- `lib/src/services/websocket_service.dart` - Serviço WebSocket
- `lib/src/ui/ipd/widgets/communication_settings_widget.dart` - Widget de configuração

#### Modificações:
- `lib/src/ui/ipd/ipd_home_controller.dart` - Adicionado suporte a WebSocket
- `lib/src/ui/ipd/ipd_home_page.dart` - Adicionado botão de configuração
- `pubspec.yaml` - Adicionada dependência `web_socket_channel`

### Sistema Python (`altitude-plataformas`)

#### Novos Arquivos:
- `controllers/websocket_controller.py` - Controlador WebSocket
- `test_websocket_client.py` - Script de teste

#### Modificações:
- `main.py` - Integração do servidor WebSocket
- `controllers/communication_controller.py` - Broadcast via WebSocket
- `requirements.txt` - Adicionada dependência `websockets`

## Como Usar

### 1. Configuração do Sistema Python

1. Instale as dependências:
```bash
cd altitude-plataformas
pip install -r requirements.txt
```

2. Execute o sistema:
```bash
python main.py
```

O servidor WebSocket será iniciado automaticamente na porta 8765.

### 2. Configuração do App Flutter

1. Instale as dependências:
```bash
cd altitude-ipd-app
flutter pub get
```

2. Execute o app:
```bash
flutter run
```

### 3. Configurando a Comunicação

1. No app Flutter, toque no ícone de configuração (cabo/WiFi) ao lado do logo
2. Escolha entre:
   - **RS485 (Serial)**: Comunicação via cabo serial (padrão)
   - **WebSocket (WiFi)**: Comunicação via rede WiFi

3. Se escolher WebSocket:
   - Digite o IP do Raspberry Pi (ex: `192.168.1.100:8765`)
   - Toque em "Conectar"
   - O status será mostrado como "Conectado" ou "Desconectado"

### 4. Testando a Conexão

Execute o script de teste no sistema Python:

```bash
cd altitude-plataformas
python test_websocket_client.py
```

Para testar apenas se o servidor está rodando:
```bash
python test_websocket_client.py server
```

## Configuração de Rede

### Para Comunicação Local

1. **Raspberry Pi**: Certifique-se de que está conectado à mesma rede WiFi
2. **App Flutter**: Use o IP local do Raspberry Pi (ex: `192.168.1.100:8765`)

### Para Descobrir o IP do Raspberry Pi

No Raspberry Pi, execute:
```bash
hostname -I
```

## Protocolo de Comunicação

### Mensagens Enviadas pelo App

```json
{
  "tipo": "comando",
  "acao": "ir_para_andar",
  "andar_destino": 2,
  "dados": null,
  "timestamp": "2024-01-01T00:00:00"
}
```

### Mensagens Recebidas pelo App

```json
{
  "tipo": "status",
  "dados": {
    "andar_atual": 1,
    "temperatura": 25.5,
    "capacidade_maxima_kg": 1000,
    "direcao_movimentacao": "Parado",
    "mensagens": ["Sistema pronto"],
    "nome_obra": "Projeto Demo",
    "codigo_obra": "DEMO001",
    "capacidade_pessoas": 8,
    "andares": {"1": {"andar": "0", "descricao": "Andar inicial"}},
    "latitude": -23.5505,
    "longitude": -46.6333,
    "data_ultima_manutencao": "2024-01-01"
  },
  "timestamp": "2024-01-01T00:00:00"
}
```

## Comandos Suportados

### Comandos Booleanos
- `ativa_manual_cabineiro` - Ativa/desativa modo manual
- `sobe_manual` - Comando de subida manual
- `desce_manual` - Comando de descida manual
- `ativa_resgate` - Ativa/desativa modo resgate
- `resgate_movimento` - Controle de movimento no modo resgate

### Comandos de Navegação
- `ir_para_andar` - Move o elevador para um andar específico
- `buscar_dados_iniciais` - Solicita dados iniciais do sistema

## Troubleshooting

### Problemas Comuns

1. **WebSocket não conecta**:
   - Verifique se o IP está correto
   - Verifique se o Raspberry Pi está na mesma rede
   - Teste com o script `test_websocket_client.py`

2. **Erro de porta**:
   - Verifique se a porta 8765 está livre
   - Reinicie o sistema Python

3. **Comunicação lenta**:
   - Verifique a qualidade da conexão WiFi
   - Considere usar RS485 para melhor performance

### Logs

O sistema Python mostra logs detalhados:
```
[WebSocket] Servidor iniciado em ws://0.0.0.0:8765
[WebSocket] Cliente conectado: 12345
[WebSocket] Mensagem recebida: {...}
```

O app Flutter mostra logs no console:
```
WebSocket conectado com sucesso
Enviando mensagem via WebSocket: {...}
```

## Vantagens da Implementação

1. **Flexibilidade**: Escolha entre RS485 e WebSocket
2. **Compatibilidade**: Não quebra funcionalidade existente
3. **Confiabilidade**: Reconexão automática
4. **Facilidade**: Interface intuitiva para configuração
5. **Performance**: Comunicação em tempo real
6. **Escalabilidade**: Suporte a múltiplos clientes

## Próximos Passos

1. **Segurança**: Implementar autenticação WebSocket
2. **Criptografia**: Adicionar SSL/TLS para comunicação segura
3. **Monitoramento**: Dashboard para status das conexões
4. **Backup**: Múltiplos servidores WebSocket
5. **Logs**: Sistema de logs mais robusto
