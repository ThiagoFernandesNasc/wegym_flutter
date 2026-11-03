# Mapa de migração Figma → Flutter

Arquivo de referência: [Wireframe WeGYM](https://www.figma.com/design/8SMaVEed7EfKTSddqtpLQE/Wireframe-WeGYM)

## Estado das telas

| Node Figma | Tela | Estado no Flutter |
|---|---|---|
| `32:2` | Dashboard Geral | Implementado em `lib/dashboard.dart`; consulta o backend e mostra resumo, treino do dia, modalidade favorita pelo histórico e atalhos de início rápido conectados às sessões de cada modalidade. Layout adaptável para desktop e celular. |
| `32:560` | Workout Builder | Editor com divisão semanal por dias (PPL, Upper/Lower, Full body, ABC, Bro split ou personalizada), seleção de atleta pelo Personal, criação/edição de exercícios e persistência via `/api/training-plans`; sessões cronometradas são registradas em `/api/workout-sessions`. |
| `32:1378` | Comunidade & Leaderboard | Tela navegável em `lib/figma_modules.dart`; feed e ações sociais usam endpoints disponíveis. Leaderboard é limitado pelos dados expostos pela API. |
| `32:2019` | Analytics & Performance | Implementado em `lib/figma_modules.dart`; períodos de semana/mês/ano, indicadores de sessões, duração, calorias, distância, frequência cardíaca e média por sessão, com gráfico de `chartData` e layout responsivo. |
| `32:2595` | Agendamentos & Avaliações | Tela navegável; consulta horários/agendamentos e permite reserva quando há identificador aceito pela API. |
| `32:3029` | Nutrição & Macronutrientes | Tela navegável; consulta planos/refeições/alimentos e permite registrar refeição conforme endpoints existentes. |
| 32:3599 | Gestão de Alunos & Personal | Tela com CRUD de alunos e Copilot contextual; o atalho na ficha envia nome e nível do atleta para `/api/chat`. Persistência real depende de backend e banco configurados. |
| `32:4310` | Metas & Desafios | Tela navegável; consulta e executa ações disponíveis de metas, desafios e conquistas. |
| `32:4878` | Programas de Treinamento | Tela navegável; lista programas e usa ações de API disponíveis. |
| `32:5393` | Chat Atleta & Coach | Tela navegável; consulta conversas e envia mensagens quando fornecido destinatário válido. |
| `32:5817` | Perfil & Configurações | Consulta/edita perfil, mostra identidade e avatar-placeholder do backend com fallback, plano ativo, integrações e consentimentos, exporta/exclui conta; OAuth Strava/Google Fit retorna via web/deep link, perfil oferece instalação PWA e atalhos responsivos. Upload persistente de avatar e preferências detalhadas ainda pendentes. |
| `32:6383` | Planos PRO & Pagamento | Planos consultam a assinatura atual; o Checkout Pro cria preferência em `/api/payment-preference`, abre o Mercado Pago e permite verificar `/api/subscriptions/me`. Retorno por deep link está implementado; pagamento real ainda depende de credenciais e validação sandbox com webhook HTTPS público. |
| `32:6860` | Login & Autenticação | Login/cadastro e recuperação de senha ligados à API, com validação de CREF e consentimentos. O Figma mostra Google, Apple e passkey; a configuração NextAuth original oferece somente credenciais, então esses botões visuais não concluem autenticação externa no Flutter e informam que o recurso não está disponível. |
| `32:7150` | Medidas & Avaliação Antropométrica | Tela navegável; consulta e registra medidas quando suportado pela API. |

As telas adicionais podem exibir amostras identificadas como prévia quando `PREVIEW_DASHBOARD=true`. Nesse modo, ações não devem gravar no servidor. A cobertura funcional varia conforme endpoint, tipo de usuário e dados disponíveis.

## Arquitetura e integração

- `lib/main.dart`: inicialização, autenticação e navegação.
- `lib/dashboard.dart`: dashboard responsivo.
- `lib/workout_builder.dart`: montagem e execução básica de sessão de musculação.
- `lib/figma_modules.dart`: módulos adicionais e ações de API.
- `lib/api.dart`: autenticação, armazenamento do token e cliente HTTP.
- `backend/`: cópia isolada do backend Next.js para desenvolvimento Flutter; o projeto de referência não é substituído.

A API configurável por `API_BASE_URL` permite manter cliente Flutter e backend Next.js como aplicações distintas. Para testar localmente, consulte o README.

## Limites conhecidos / próximos passos

1. Comparar cada módulo com o node completo no Figma e ajustar componentes, assets, tipografia, espaçamento e estados responsivos.
2. Validar autenticação, ações CRUD e autorização com os papéis atleta e personal, incluindo estados de erro e ausência de dados.
3. Rever rotas cujo contrato ou autorização não seja compatível com o cliente móvel.
4. Validar BLE, Health Connect/Apple Health e lembretes locais em aparelhos físicos. O GPS em primeiro plano corresponde ao comportamento atual da referência mobile; Health Connect e lembretes diários já foram migrados. A fila offline ainda precisa cobrir outras operações e conflitos.
5. Configurar e testar integrações externas (MercadoPago e provedores de autenticação) com credenciais válidas.

A existência de uma tela/ação no Flutter não garante por si só a mesma cobertura funcional ou fidelidade visual do aplicativo original. Estes pontos devem ser validados conforme o ambiente e as credenciais usados na apresentação.

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


## Inventario do arquivo visual final

Arquivo: https://www.figma.com/design/fDKnyOHhC0sObhYiCpBtMF/Sem-t%C3%ADtulo

A pagina `0:1` contem 14 frames. Os nomes correspondem as 14 areas ja mapeadas acima; nao apareceu uma categoria de tela adicional. Este inventario registra IDs e dimensoes sem solicitar novamente os renders das telas que ja foram vistos.

| Node final | Tela | Dimensoes Figma |
| --- | --- | --- |
| `1:15610` | Dashboard Geral | 1280 x 1394 |
| `1:16168` | Workout Builder | 1280 x 1724 |
| `1:16986` | Comunidade e Leaderboard | 1280 x 1442 |
| `1:17627` | Analytics e Performance | 1280 x 1621.5 |
| `1:18203` | Agendamentos e Avaliacoes | 1280 x 1276.2 |
| `1:18637` | Nutricao e Macronutrientes | 1280 x 1496 |
| `1:19207` | Gestao de Alunos e Personal | 1280 x 1698.5 |
| `1:19918` | Metas e Desafios | 1280 x 1728 |
| `1:20486` | Programas de Treinamento | 1280 x 1677 |
| `1:21001` | Chat Atleta e Coach | 1280 x 1338.5 |
| `1:21425` | Perfil e Configuracoes | 1327.1 x 1776 |
| `1:21991` | Planos PRO e Pagamento | 1280 x 1755 |
| `1:22468` | Login e Autenticacao | 1280 x 1024 |
| `1:22758` | Medidas e Avaliacao Antropometrica | 1280 x 2122 |
