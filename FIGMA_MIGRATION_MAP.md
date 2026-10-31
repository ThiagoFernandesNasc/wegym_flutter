# Mapa de migraÃ§Ã£o Figma â†’ Flutter

Arquivo de referÃªncia: [Wireframe WeGYM](https://www.figma.com/design/8SMaVEed7EfKTSddqtpLQE/Wireframe-WeGYM)

## Estado das telas

| Node Figma | Tela | Estado no Flutter |
|---|---|---|
| `32:2` | Dashboard Geral | Implementado em `lib/dashboard.dart`; consulta perfil, estatÃ­sticas, sessÃµes, plano e feed quando a API estÃ¡ disponÃ­vel. |
| `32:560` | Workout Builder | Implementado em `lib/workout_builder.dart`; ediÃ§Ã£o de exercÃ­cios, sÃ©ries/reps/carga, modelo local, volume muscular, cronÃ´metro, registro de sessÃ£o e tentativa de salvar plano. |
| `32:1378` | Comunidade & Leaderboard | Tela navegÃ¡vel em `lib/figma_modules.dart`; feed e aÃ§Ãµes sociais usam endpoints disponÃ­veis. Leaderboard Ã© limitado pelos dados expostos pela API. |
| `32:2019` | Analytics & Performance | Tela navegÃ¡vel; usa estatÃ­sticas, sessÃµes e medidas disponÃ­veis. Indicadores nÃ£o equivalem a todas as anÃ¡lises do app original. |
| `32:2595` | Agendamentos & AvaliaÃ§Ãµes | Tela navegÃ¡vel; consulta horÃ¡rios/agendamentos e permite reserva quando hÃ¡ identificador aceito pela API. |
| `32:3029` | NutriÃ§Ã£o & Macronutrientes | Tela navegÃ¡vel; consulta planos/refeiÃ§Ãµes/alimentos e permite registrar refeiÃ§Ã£o conforme endpoints existentes. |
| `32:3599` | GestÃ£o de Alunos & Personal | Tela navegÃ¡vel; consulta dados do perfil/personal e atletas acessÃ­veis pela API. |
| `32:4310` | Metas & Desafios | Tela navegÃ¡vel; consulta e executa aÃ§Ãµes disponÃ­veis de metas, desafios e conquistas. |
| `32:4878` | Programas de Treinamento | Tela navegÃ¡vel; lista programas e usa aÃ§Ãµes de API disponÃ­veis. |
| `32:5393` | Chat Atleta & Coach | Tela navegÃ¡vel; consulta conversas e envia mensagens quando fornecido destinatÃ¡rio vÃ¡lido. |
| `32:5817` | Perfil & ConfiguraÃ§Ãµes | Parcial; consulta perfil, integraÃ§Ã£o/assinatura disponÃ­veis e permite encerrar sessÃ£o. EdiÃ§Ã£o abrangente e preferÃªncias pendentes. |
| `32:6383` | Planos PRO & Pagamento | Parcial; apresenta planos e encaminha para configuraÃ§Ã£o MercadoPago. Pagamento real depende de credenciais e validaÃ§Ã£o ponta a ponta. |
| `32:6860` | Login & AutenticaÃ§Ã£o | Login/cadastro ligados Ã  API; recuperaÃ§Ã£o de senha chama endpoint. Provedores sociais e todos os estados ainda nÃ£o foram migrados. |
| `32:7150` | Medidas & AvaliaÃ§Ã£o AntropomÃ©trica | Tela navegÃ¡vel; consulta e registra medidas quando suportado pela API. |

As telas adicionais podem exibir amostras identificadas como prÃ©via quando `PREVIEW_DASHBOARD=true`. Nesse modo, aÃ§Ãµes nÃ£o devem gravar no servidor. A cobertura funcional varia conforme endpoint, tipo de usuÃ¡rio e dados disponÃ­veis.

## Arquitetura e integraÃ§Ã£o

- `lib/main.dart`: inicializaÃ§Ã£o, autenticaÃ§Ã£o e navegaÃ§Ã£o.
- `lib/dashboard.dart`: dashboard responsivo.
- `lib/workout_builder.dart`: montagem e execuÃ§Ã£o bÃ¡sica de sessÃ£o de musculaÃ§Ã£o.
- `lib/figma_modules.dart`: mÃ³dulos adicionais e aÃ§Ãµes de API.
- `lib/api.dart`: autenticaÃ§Ã£o, armazenamento do token e cliente HTTP.
- `backend/`: cÃ³pia isolada do backend Next.js para desenvolvimento Flutter; o projeto de referÃªncia nÃ£o Ã© substituÃ­do.

A API configurÃ¡vel por `API_BASE_URL` permite manter cliente Flutter e backend Next.js como aplicaÃ§Ãµes distintas. Para testar localmente, consulte o README.

## Limites conhecidos / prÃ³ximos passos

1. Comparar cada mÃ³dulo com o node completo no Figma e ajustar componentes, assets, tipografia, espaÃ§amento e estados responsivos.
2. Validar autenticaÃ§Ã£o, aÃ§Ãµes CRUD e autorizaÃ§Ã£o com os papÃ©is atleta e personal, incluindo estados de erro e ausÃªncia de dados.
3. Rever rotas cujo contrato ou autorizaÃ§Ã£o nÃ£o seja compatÃ­vel com o cliente mÃ³vel.
4. Migrar recursos que dependem do hardware/plataforma: GPS em segundo plano, Bluetooth, Health Connect/Apple Health, notificaÃ§Ãµes push e modo offline.
5. Configurar e testar integraÃ§Ãµes externas (MercadoPago e provedores de autenticaÃ§Ã£o) com credenciais vÃ¡lidas.

A existÃªncia de uma tela/aÃ§Ã£o no Flutter nÃ£o garante por si sÃ³ a mesma cobertura funcional ou fidelidade visual do aplicativo original. Estes pontos devem ser validados conforme o ambiente e as credenciais usados na apresentaÃ§Ã£o.

## Regressions found and corrected during integration review

- Corrected Flutter shell navigation: Profile opens the profile page, More opens the module picker, and the header title reflects the active page instead of showing Profile for every module index above 3.
- Analytics now unwraps the backend `{ data: ... }` envelope. Community ranking calls the real leaderboard endpoint for each challenge; the backend has no global community leaderboard endpoint.
- The login form no longer asks users to choose a role while signing in. The backend account's `role` is authoritative. The original Next.js app routes `atleta` users to the athlete home and `personal` users to the coaching area.
- Flutter now sends Personal accounts to the coaching/student-management area at startup and avoids athlete-only analytics/measurement endpoints for Personal accounts. Athlete accounts see a clear access message when opening Personal-only management.
- Replaced the unsupported `unstable_cache.noop()` call in the isolated Next.js copy's social POST route with the Next.js 16 `revalidateTag(tag, "max")` API. An authenticated local POST was verified to return HTTP 201. This fix must also be carried into whichever backend source is deployed; the original backend source remains unchanged.
- Authenticated read-only route checks on the local demo backend returned HTTP 200 for common athlete and Personal routes. Expected role-specific responses are 403/404 (athletes cannot list coaching rosters; Personal accounts do not have an individual Athlete metrics record); Flutter now handles these cases as role guidance instead of raw server errors.
- The pre-existing `test/widget_test.dart` targeted a removed `MyApp` counter template. It now checks the actual login page and passed.

The Flutter widget smoke test passed; Flutter web release build passed; the isolated Next.js production build and TypeScript check passed; and the production backend health/login/CORS/social POST checks passed locally. A Flutter release web build still needs `API_BASE_URL` set to the deployed backend HTTPS address. A bundle compiled against `localhost` is only suitable for local use.

## Revisao de autenticacao Figma e pacote Android

- O no `32:6860` corresponde a tela de autenticacao e foi conferido no Figma. O `LoginPage` em `lib/main.dart` e a correspondencia no Flutter. A tela do Figma e uma composicao web desktop; no Flutter, a apresentacao permanece responsiva e a autenticacao continua usando a role real retornada pela API, sem permitir trocar o tipo de conta durante o login.
- Provedores Google/Apple e Passkey mostrados no Figma nao foram apresentados como botoes funcionais porque nao existem integracoes configuradas para eles no cliente Flutter/backend desta copia.
- O wrapper Gradle estava sem `distributionUrl` e tinha a chave `ozipStoreBase` incorreta. Foi corrigido para Gradle 8.14, compativel com o Android Gradle Plugin declarado.
- O manifesto release nao tinha permissao `INTERNET`; foi adicionada. HTTP cleartext esta habilitado para a demo local no emulador (API `10.0.2.2:3001`). Isso precisa ser substituido por HTTPS antes de publicar.
- APK release compilado em `build/app/outputs/flutter-apk/app-release.apk`. Usa assinatura de debug e nao e uma versao pronta para Play Store.

## Próxima etapa

- [x] Revisar e aproximar a tela **Treinos / Workout Builder** do Stitch, preservando a criação e edição de exercícios, séries, repetições, cargas, cronômetro e salvamento de sessões/planos pela API.
  Nota: fotos e detalhes por série exibidos no Stitch (RPE, cadência e descanso) não existem no modelo/API atual; o Flutter mantém os campos reais disponíveis sem simular esses dados.

