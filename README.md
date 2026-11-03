# WeGYM Flutter

Aplicativo Flutter/Dart com interface adaptÃ¡vel para web e dispositivos mÃ³veis. O projeto da apresentaÃ§Ã£o fica em `C:\Users\thiag\Downloads\wegym_flutter`; o Next.js original estÃ¡ em `C:\Users\thiag\Downloads\wegym-master\wegym-master`. O backend Next.js continua sendo usado. Os arquivos `.env` nÃ£o foram lidos nem alterados.

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

No celular fÃ­sico, substitua `10.0.2.2` pelo IP local do computador. Para Flutter Web local, o backend permite `http://localhost:7358`; em produÃ§Ã£o, configure `CORS_ALLOWED_ORIGIN` com a origem HTTPS do app e nÃ£o publique apontando para `localhost`.

## Interface responsiva para web e dispositivos mÃ³veis

O Flutter adapta a navegaÃ§Ã£o e o conteÃºdo conforme a largura disponÃ­vel: em janelas largas, usa barra lateral; em celulares, usa navegaÃ§Ã£o inferior e reorganiza os painÃ©is. A mesma base Dart atende Ã  web, Android e iOS. Recursos que dependem de APIs especÃ­ficas do aparelho (como BLE, GPS e deep links) variam conforme a plataforma e estÃ£o descritos nas pendÃªncias abaixo.

Para executar no Brave com backend e escolher entre os modos Web e Mobile:

```powershell
.\scripts\run_preview.ps1
```

A prÃ©via abre com o seletor Web/Mobile; escolha Web para o layout amplo ou Mobile para visualizar a moldura do aparelho. Use `-NoDeviceFrame` para abrir diretamente no layout Web. Em celular fÃ­sico, o Flutter ocupa a tela e responde Ã  largura real, sem a moldura de demonstraÃ§Ã£o. Para executar no Android, use `flutter run -d android`; para iOS, use macOS com Xcode e `flutter run -d ios`.

## Funcionalidades e integraÃ§Ãµes

O Flutter inclui autenticaÃ§Ã£o por e-mail, cadastro, recuperaÃ§Ã£o de senha, consulta dos Termos de Uso e da PolÃ­tica de Privacidade (tambÃ©m acessÃ­veis pelo perfil), dashboard, atividade/histÃ³rico, ediÃ§Ã£o e sessÃ£o de treinos, comunidade, catÃ¡logo de conquistas, analytics, agenda, nutriÃ§Ã£o, alunos/Personal, metas, programas, chat, perfil, assinatura, medidas, check-in, amigos e aulas. No fluxo do Personal, cadastro, ficha, ediÃ§Ã£o, desvinculaÃ§Ã£o e evoluÃ§Ã£o fÃ­sica usam os endpoints do backend; os fluxos foram cobertos por testes com API simulada, e a persistÃªncia real depende da configuraÃ§Ã£o do banco.

Na musculaÃ§Ã£o, cada sÃ©rie pode ser confirmada com carga e repetiÃ§Ãµes executadas. O dashboard calcula o volume semanal apenas com sÃ©ries confirmadas; a prÃ©via usa um valor demonstrativo local.

O assistente de IA fica no botÃ£o flutuante das telas compactas e na Ã¡rea Treinos em janelas largas. No modo conectado, usa a sessÃ£o autenticada e o endpoint Next.js `/api/chat` para gerar sugestÃµes e exercÃ­cios com Gemini; configure `GEMINI_API_KEY` em `backend/.env`. Na prÃ©via, oferece sugestÃµes locais identificadas como demonstraÃ§Ã£o, sem chamar o backend, e permite iniciar a sessÃ£o com esses exercÃ­cios. A chave permanece no servidor.

O Checkout Pro do Mercado Pago estÃ¡ conectado para os planos mensal e anual. O valor e o plano sÃ£o definidos no backend, e os dados do cartÃ£o sÃ£o digitados no ambiente hospedado do Mercado Pago. Para habilitar compras, configure `MP_ACCESS_TOKEN`, `NEXTAUTH_URL` pÃºblico HTTPS e `MP_WEBHOOK_SECRET` em `backend/.env`; sem webhook pÃºblico, a cobranÃ§a pode ser concluÃ­da no provedor, mas a assinatura nÃ£o serÃ¡ ativada automaticamente no app. O retorno ao app por deep link e uma compra de sandbox ainda precisam de validaÃ§Ã£o com as credenciais configuradas.

A atividade GPS funciona em primeiro plano e salva o percurso pela API. A tela de sensores BLE busca sensores de frequÃªncia cardÃ­aca Heart Rate (0x180D), exibe BPM e histÃ³rico e lÃª a bateria quando disponÃ­vel. BLE estÃ¡ implementado para Android/iOS e para web em navegadores/dispositivos compatÃ­veis; ainda nÃ£o foi testado com sensor fÃ­sico. Na web, a API Bluetooth requer navegador compatÃ­vel, origem segura (HTTPS ou localhost) e permissÃ£o explÃ­cita do usuÃ¡rio.

Perfil e estatÃ­sticas consultados tÃªm cache local. Treinos concluÃ­dos sem conexÃ£o entram em fila e podem sincronizar ao retomar o app ou manualmente. A fila ainda nÃ£o cobre todas as operaÃ§Ãµes nem resolve conflitos.
Na comunidade, participar de um desafio envia a aÃ§Ã£o ao backend e abre o ranking em uma tela prÃ³pria. A prÃ©via inclui participantes hipotÃ©ticos identificados como fictÃ­cios; esses dados nÃ£o sÃ£o enviados ao servidor.


No cadastro, atletas informam seus dados fÃ­sicos, endereÃ§o e informaÃ§Ãµes de saÃºde, com consulta opcional de CEP pelo ViaCEP. O cadastro Personal verifica o CREF no backend antes de liberar a criaÃ§Ã£o da conta.


No perfil, a exportaÃ§Ã£o baixa os dados retornados pelo backend em `dados-pessoais.json`. A exclusÃ£o da conta exige confirmaÃ§Ã£o digitando `EXCLUIR` e encerra a sessÃ£o depois que o backend confirma.
O perfil web tambÃ©m oferece instalaÃ§Ã£o PWA: usa o convite nativo do navegador quando disponÃ­vel e mostra instruÃ§Ãµes nos navegadores sem esse convite.

No Android e iOS, o perfil permite ativar ou cancelar um lembrete local de treino Ã s 7h, com o fuso do aparelho. No Android, o sistema restaura o lembrete apÃ³s reinicializaÃ§Ã£o. Esse recurso Ã© local; notificaÃ§Ãµes push remotas nÃ£o estÃ£o configuradas.

## APK para apresentaÃ§Ã£o

Para gerar o APK release com login demonstrativo de atleta/Personal, sem exigir credenciais externas para iniciar a demonstraÃ§Ã£o:

```powershell
flutter build apk --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true
```

O arquivo gerado fica em `build/app/outputs/flutter-apk/app-release.apk` (57,3 MB no build verificado em 02/11/2026). A tela de login exibe os acessos de demonstraÃ§Ã£o. Para um build conectado ao backend real, remova os defines de prÃ©via e configure a URL da API para o dispositivo.

## Modalidades de treino

O editor abre sessÃµes de nataÃ§Ã£o, aerÃ³bico e luta, alÃ©m da musculaÃ§Ã£o. Essas sessÃµes registram a duraÃ§Ã£o pela rota `/api/workout-sessions`; na nataÃ§Ã£o, voltas e tamanho da piscina determinam a distÃ¢ncia. Corrida, ciclismo, caminhada e trilha usam a tela GPS.

## Retorno do Checkout Pro em web e dispositivos mÃ³veis

O checkout agora informa ao backend se foi aberto pelo app web ou por um dispositivo nativo. Android e iOS recebem o retorno pelo esquema `wegym://payment-return`; na web, configure `FLUTTER_APP_URL` em `backend/.env` com a origem HTTPS publicada do Flutter. O app consulta `/api/subscriptions/me` ao retornar e sÃ³ mostra a assinatura como ativa quando o backend confirma o estado. O valor deve ser uma URL HTTPS pÃºblica; endereÃ§os localhost nÃ£o sÃ£o aceitos pelo Mercado Pago como URL de retorno.

Strava e Google Fit recebem `flutter_web` ou `flutter_native` em um estado OAuth assinado. O backend salva os tokens e retorna ao perfil Flutter; no nativo usa `wegym://integration-return`, e na web usa `FLUTTER_APP_URL`. O script de prÃ©via define `http://localhost:7358` automaticamente. Para provedores reais, configure as credenciais e os callbacks HTTPS cadastrados no Google/Strava.

O retorno e o webhook precisam ser validados em uma compra de sandbox com as credenciais do provedor. Nenhum arquivo `.env` foi preenchido.

## PendÃªncias para paridade

- Validar login, CRUDs e persistÃªncia com credenciais e banco reais.
- Configurar a chave Gemini e as credenciais do Mercado Pago no backend; validar IA, checkout de sandbox e webhook com contas autenticadas.
- Comparar as telas finais com Figma/Stitch, incluindo navegaÃ§Ã£o, acessibilidade por perfil, responsividade e textos.
- Validar Health Connect/Apple Health, lembretes locais e BLE em aparelhos fÃ­sicos; testar OAuth Google/Strava com credenciais reais e passkey/biometria se esses recursos entrarem no escopo da apresentaÃ§Ã£o.
- Ampliar a fila offline para outras operaÃ§Ãµes e definir como resolver conflitos de sincronizaÃ§Ã£o.
- Validar BLE com sensor fÃ­sico.
- Validar Android em dispositivo ou emulador; SDK/API 36 instalado e APKs debug/release compilados. iOS requer macOS e Xcode.

O plugin BLE suporta BLE Central em Android, iOS, Linux, macOS e web; uso educacional Ã© gratuito conforme a licenÃ§a publicada. Consulte a [documentaÃ§Ã£o oficial](https://pub.dev/packages/flutter_blue_plus).

## VerificaÃ§Ã£o

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --dart-define=PREVIEW_DASHBOARD=true
flutter build web --release --no-pub
flutter build apk --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true
```

VerificaÃ§Ã£o de 02/11/2026: `flutter analyze --no-pub` passou sem problemas. A suÃ­te conectada passou com 57 testes e 12 cenÃ¡rios de demonstraÃ§Ã£o ignorados; com `PREVIEW_DASHBOARD=true`, 39 testes passaram e 30 cenÃ¡rios conectados foram ignorados. Os builds web, APK debug e APK release demonstrativo concluÃ­ram. O APK release estÃ¡ em `build/app/outputs/flutter-apk/app-release.apk` (57,3 MB); o debug tem 185 MB e Ã© destinado a desenvolvimento.

Na verificaÃ§Ã£o de 01/11/2026, anÃ¡lise, testes e build web passaram; o SDK Android foi instalado depois e `flutter build apk --debug --no-pub` compilou `build/app/outputs/flutter-apk/app-debug.apk`. IA, pagamentos reais e integraÃ§Ãµes com hardware ainda dependem de credenciais e validaÃ§Ã£o no ambiente configurado.
