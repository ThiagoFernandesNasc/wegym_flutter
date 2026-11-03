# WeGYM Flutter

Aplicativo Flutter/Dart responsivo para web e dispositivos móveis. O projeto da apresentação está em `C:\Users\thiag\Downloads\wegym_flutter`; a pasta original `C:\Users\thiag\Downloads\wegym-master\wegym-master` permanece como referência. O app Flutter usa o backend Next.js incluído em `backend/`. Configure as variáveis locais em `backend/.env`; esse arquivo não deve ser enviado ao Git.

## Executar

Backend, em um terminal PowerShell:

```powershell
cd C:\Users\thiag\Downloads\wegym_flutter\backend
npm run dev
```

Flutter na web:

```powershell
cd C:\Users\thiag\Downloads\wegym_flutter
flutter pub get
flutter run -d chrome --web-port=7358 --dart-define=API_BASE_URL=http://localhost:3000
```

Android (com Android SDK instalado):

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

No celular físico, substitua `10.0.2.2` pelo IP local do computador. Para Flutter Web local, o backend permite `http://localhost:7358`; em produção, configure `CORS_ALLOWED_ORIGIN` com a origem HTTPS do app e não publique apontando para `localhost`.

## Interface responsiva para web e dispositivos móveis

O Flutter adapta a navegação e o conteúdo conforme a largura disponível: em janelas largas, usa barra lateral; em celulares, usa navegação inferior e reorganiza os painéis. A mesma base Dart atende à web, Android e iOS. Recursos que dependem de APIs específicas do aparelho (como BLE, GPS e deep links) variam conforme a plataforma e estão descritos nas pendências abaixo.

Para executar no Brave com backend e escolher entre os modos Web e Mobile:

```powershell
.\scripts\run_preview.ps1
```

A prévia abre com o seletor Web/Mobile; escolha Web para o layout amplo ou Mobile para visualizar a moldura do aparelho. Use `-NoDeviceFrame` para abrir diretamente no layout Web. Em celular físico, o Flutter ocupa a tela e responde à largura real, sem a moldura de demonstração. Para executar no Android, use `flutter run -d android`; para iOS, use macOS com Xcode e `flutter run -d ios`.

## Funcionalidades e integrações

O Flutter inclui autenticação por e-mail, cadastro, recuperação de senha, consulta dos Termos de Uso e da Política de Privacidade (também acessíveis pelo perfil), dashboard, atividade/histórico, edição e sessão de treinos, comunidade, catálogo de conquistas, analytics, agenda, nutrição, alunos/Personal, metas, programas, chat, perfil, assinatura, medidas, check-in, amigos e aulas. No fluxo do Personal, cadastro, ficha, edição, desvinculação e evolução física usam os endpoints do backend; os fluxos foram cobertos por testes com API simulada, e a persistência real depende da configuração do banco.

Na musculação, cada série pode ser confirmada com carga e repetições executadas. O dashboard calcula o volume semanal apenas com séries confirmadas; a prévia usa um valor demonstrativo local.

O assistente de IA fica no botão flutuante das telas compactas e na área Treinos em janelas largas. No modo conectado, usa a sessão autenticada e o endpoint Next.js `/api/chat` para gerar sugestões e exercícios com Gemini; configure `GEMINI_API_KEY` em `backend/.env`. Na prévia, oferece sugestões locais identificadas como demonstração, sem chamar o backend, e permite iniciar a sessão com esses exercícios. A chave permanece no servidor.

O Checkout Pro do Mercado Pago está conectado para os planos mensal e anual. O valor e o plano são definidos no backend, e os dados do cartão são digitados no ambiente hospedado do Mercado Pago. Para habilitar compras, configure `MP_ACCESS_TOKEN`, `NEXTAUTH_URL` público HTTPS e `MP_WEBHOOK_SECRET` em `backend/.env`; sem webhook público, a cobrança pode ser concluída no provedor, mas a assinatura não será ativada automaticamente no app. O retorno ao app por deep link e uma compra de sandbox ainda precisam de validação com as credenciais configuradas.

A atividade GPS funciona em primeiro plano e salva o percurso pela API. A tela de sensores BLE busca sensores de frequência cardíaca Heart Rate (0x180D), exibe BPM e histórico e lê a bateria quando disponível. BLE está implementado para Android/iOS e para web em navegadores/dispositivos compatíveis; ainda não foi testado com sensor físico. Na web, a API Bluetooth requer navegador compatível, origem segura (HTTPS ou localhost) e permissão explícita do usuário.

Perfil e estatísticas consultados têm cache local. Treinos concluídos sem conexão entram em fila e podem sincronizar ao retomar o app ou manualmente. A fila ainda não cobre todas as operações nem resolve conflitos.
Na comunidade, participar de um desafio envia a ação ao backend e abre o ranking em uma tela própria. A prévia inclui participantes hipotéticos identificados como fictícios; esses dados não são enviados ao servidor.

No cadastro, atletas informam seus dados físicos, endereço e informações de saúde, com consulta opcional de CEP pelo ViaCEP. O cadastro Personal verifica o CREF no backend antes de liberar a criação da conta.

No perfil, a exportação baixa os dados retornados pelo backend em `dados-pessoais.json`. A exclusão da conta exige confirmação digitando `EXCLUIR` e encerra a sessão depois que o backend confirma.
O perfil web também oferece instalação PWA: usa o convite nativo do navegador quando disponível e mostra instruções nos navegadores sem esse convite.

No Android e iOS, o perfil permite ativar ou cancelar um lembrete local de treino às 7h, com o fuso do aparelho. No Android, o sistema restaura o lembrete após reinicialização. Esse recurso é local; notificações push remotas não estão configuradas.

## APK para apresentação

Para gerar o APK release com login demonstrativo de atleta/Personal, sem exigir credenciais externas para iniciar a demonstração:

```powershell
flutter build apk --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true
```

O arquivo gerado fica em `build/app/outputs/flutter-apk/app-release.apk` (57,3 MB no build verificado em 02/11/2026). A tela de login exibe os acessos de demonstração. Para um build conectado ao backend real, remova os defines de prévia e configure a URL da API para o dispositivo.

## Modalidades de treino

O editor abre sessões de natação, aeróbico e luta, além da musculação. Essas sessões registram a duração pela rota `/api/workout-sessions`; na natação, voltas e tamanho da piscina determinam a distância. Corrida, ciclismo, caminhada e trilha usam a tela GPS.

## Retorno do Checkout Pro em web e dispositivos móveis

O checkout agora informa ao backend se foi aberto pelo app web ou por um dispositivo nativo. Android e iOS recebem o retorno pelo esquema `wegym://payment-return`; na web, configure `FLUTTER_APP_URL` em `backend/.env` com a origem HTTPS publicada do Flutter. O app consulta `/api/subscriptions/me` ao retornar e só mostra a assinatura como ativa quando o backend confirma o estado. O valor deve ser uma URL HTTPS pública; endereços localhost não são aceitos pelo Mercado Pago como URL de retorno.

Strava e Google Fit recebem `flutter_web` ou `flutter_native` em um estado OAuth assinado. O backend salva os tokens e retorna ao perfil Flutter; no nativo usa `wegym://integration-return`, e na web usa `FLUTTER_APP_URL`. O script de prévia define `http://localhost:7358` automaticamente. Para provedores reais, configure as credenciais e os callbacks HTTPS cadastrados no Google/Strava.

O retorno e o webhook precisam ser validados em uma compra de sandbox com as credenciais do provedor.
## Pendências para paridade

- Validar login, CRUDs e persistência com credenciais e banco reais.
- Configurar a chave Gemini e as credenciais do Mercado Pago no backend; validar IA, checkout de sandbox e webhook com contas autenticadas.
- Comparar as telas finais com Figma/Stitch, incluindo navegação, acessibilidade por perfil, responsividade e textos.
- Validar Health Connect/Apple Health, lembretes locais e BLE em aparelhos físicos; testar OAuth Google/Strava com credenciais reais e passkey/biometria se esses recursos entrarem no escopo da apresentação.
- Ampliar a fila offline para outras operações e definir como resolver conflitos de sincronização.
- Validar BLE com sensor físico.
- Validar o app Android em um dispositivo ou emulador. O SDK/API 36 e os builds APK debug e release já foram verificados. Para iOS, é necessário usar macOS e Xcode.

O plugin BLE suporta BLE Central em Android, iOS, Linux, macOS e web; uso educacional é gratuito conforme a licença publicada. Consulte a [documentação oficial](https://pub.dev/packages/flutter_blue_plus).

## Verificação

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --dart-define=PREVIEW_DASHBOARD=true
flutter build web --release --no-pub
flutter build apk --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true
```

Na verificação de 02/11/2026, a análise estática não encontrou erros de compilação; foram registrados avisos informativos de estilo. A suíte conectada passou com 57 testes e 12 cenários de demonstração ignorados; com `PREVIEW_DASHBOARD=true`, 39 testes passaram e 30 cenários conectados foram ignorados. Os builds web, APK debug e APK release demonstrativo concluíram. O APK release está em `build/app/outputs/flutter-apk/app-release.apk` (57,3 MB); o debug tem 185 MB e é destinado a desenvolvimento.

Na verificação de 01/11/2026, análise, testes e build web passaram; o SDK Android foi instalado depois e `flutter build apk --debug --no-pub` compilou `build/app/outputs/flutter-apk/app-debug.apk`. IA, pagamentos reais e integrações com hardware ainda dependem de credenciais e validação no ambiente configurado.
