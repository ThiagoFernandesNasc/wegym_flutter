# WeGYM Flutter

Aplicativo Flutter/Dart responsivo para web e dispositivos móveis. O app Flutter usa o backend Next.js incluído em `backend/`. Configure as variáveis locais em `backend/.env`; esse arquivo não deve ser enviado ao Git. Os comandos abaixo usam caminhos relativos e funcionam na pasta em que o projeto foi clonado ou extraído.

## Executar

Abra um terminal na raiz do projeto (a pasta que contém `pubspec.yaml` e `backend/`). Inicie o backend:

```powershell
cd backend
npm run dev
```

Em outro terminal, também na raiz do projeto, inicie o Flutter Web:

```powershell
flutter pub get
flutter run -d chrome --web-port=7358 --dart-define=API_BASE_URL=http://localhost:3000
```

Para Android, com o Android SDK instalado, execute na raiz do projeto:

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

