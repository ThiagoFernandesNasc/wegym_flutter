## Roteiro da apresentação

### Problema e público-alvo

O WeGYM busca facilitar o acompanhamento da rotina de exercícios e da evolução física. A plataforma reúne treinos, metas, indicadores de atividade e comunicação em um só lugar, ajudando o atleta a acompanhar sua consistência e o profissional de Educação Física a organizar o atendimento de seus alunos.

O público-alvo são atletas e praticantes de atividade física, personal trainers e academias que precisam acompanhar treinos e evolução. O acesso e as ações disponíveis variam conforme o perfil de atleta ou Personal.

### Navegação e principais funcionalidades

Na apresentação, comece pelo login ou escolha um dos perfis de demonstração. Use a navegação lateral no modo Web ou a navegação compacta no modo Mobile. As principais áreas são:

- **Visão Geral e Atividade:** resumo de métricas, sessões e histórico.
- **Treinos:** planejamento semanal, divisão por dias, exercícios, séries e registro de sessões.
- **Comunidade e Metas & Desafios:** publicações, comentários, desafios, participantes e conquistas.
- **Nutrição:** diário de refeições, busca e seleção de alimentos e acompanhamento de nutrientes.
- **Alunos & Personal:** gestão de alunos vinculados e recursos de acompanhamento para o perfil Personal.
- **Agenda, Medidas, Check-in, Chat e Aulas:** recursos de organização e acompanhamento descritos nas respectivas telas.
- **Assistente de IA:** sugestões de treino pelo backend com Gemini, quando a chave e a sessão estiverem configuradas.

Algumas ações dependem do backend, do banco de dados e de credenciais externas. Para uma demonstração sem esses serviços, o projeto também oferece modo de prévia com dados identificados como demonstrativos; esses dados locais não representam gravações no banco.

### Protótipo e aplicativo

O protótipo do Figma/Stitch definiu a identidade visual escura, o uso de laranja como cor de destaque, a hierarquia dos painéis e os fluxos principais. No aplicativo, essa linguagem visual foi adaptada para Flutter e para diferentes larguras de tela: a navegação e os painéis se reorganizam entre Web e Mobile.

As alterações de interface foram feitas para tornar os controles utilizáveis em telas menores e conectar as ações aos fluxos de autenticação e aos endpoints disponíveis. Quando um fluxo depende de um serviço ou de uma credencial que não está configurada, ele pode apresentar uma limitação ou usar dados de demonstração; consulte **Pendências para paridade** antes da apresentação. Compare cada tela implementada com o protótipo durante a apresentação e explique as diferenças observadas no dispositivo utilizado.

### Organização do código, desafios e soluções

- `lib/` contém a aplicação Flutter/Dart, as telas, widgets e clientes usados para comunicar com a API.
- `backend/` contém a aplicação Next.js, suas rotas de API, serviços, validações e o schema/migrações do Prisma.
- `assets/` e os arquivos de configuração do Flutter reúnem recursos visuais e configuração por plataforma.
- `test/` contém testes automatizados do app.

Um desafio central foi manter os fluxos do projeto original ao adaptar a interface para Flutter e Web/Mobile. A solução é manter o backend como serviço da aplicação, concentrar a interface e a navegação no cliente Flutter e tratar separadamente os perfis de atleta e Personal. A responsividade também exige reorganizar painéis e navegação sem esconder as ações essenciais. A prévia facilita a demonstração, mas deve ser distinguida dos dados persistidos no backend.

### Flutter, Dart e conceitos de dispositivos móveis

O Flutter foi escolhido para construir a interface com uma única base de código que pode ser executada na Web e em aplicativos móveis. A interface é descrita em Dart como uma árvore de widgets: telas, cartões, campos, botões e barras de navegação são widgets que podem ser compostos e reutilizados. O Material Design fornece componentes e padrões de interação comuns, que o projeto personaliza com o tema visual do WeGYM.

Os conceitos aparecem no código desta forma:

- **Widgets com e sem estado:** `StatelessWidget` representa partes que só dependem dos dados recebidos; `StatefulWidget` mantém estado que muda durante o uso. Em `main.dart`, `AppShell` controla a área selecionada. Em `workout_builder.dart`, a sessão atualiza exercícios, séries e cronômetro. `setState` pede ao Flutter para reconstruir a parte da interface afetada pela mudança.
- **Composição e reutilização:** telas são montadas combinando widgets menores. `dashboard.dart` reúne cartões e painéis; `figma_modules.dart` apresenta módulos funcionais; `stitch_design_system.dart` centraliza elementos visuais reutilizáveis. Isso ajuda a manter uma aparência consistente e facilita ajustes.
- **Layout adaptável:** `LayoutBuilder` e `MediaQuery` leem o espaço disponível para reorganizar conteúdo. `main.dart` alterna entre navegação lateral em janelas largas e navegação inferior em telas estreitas. `device_frame_preview.dart` oferece um seletor visual Web/Mobile para demonstração no navegador; ele não substitui o teste em um aparelho real.
- **Navegação e ciclo de tela:** `MaterialApp`, `Scaffold` e `Navigator` organizam as páginas e as transições. Em telas como `gps_session_page.dart`, ações assíncronas atualizam a interface apenas enquanto o widget continua ativo, e recursos como streams e timers são encerrados ao sair da tela.
- **Programação assíncrona:** chamadas de rede, GPS e armazenamento levam tempo. Dart usa `Future` e `async`/`await` para aguardar essas operações sem congelar a interface. `FutureBuilder` exibe estados de carregamento, resultado ou erro em páginas que dependem de uma resposta assíncrona.
- **Integração com serviços e armazenamento seguro:** `api.dart` concentra requisições HTTP ao backend Next.js e o uso do token da sessão; `offline_storage.dart` mantém cache e sessões de treino pendentes em armazenamento seguro local. O servidor continua responsável pelas regras de negócio e pela persistência compartilhada no banco.
- **Recursos do aparelho:** `gps_session_page.dart` usa localização para registrar percursos; `ble_monitor_page.dart` consulta sensores Bluetooth de frequência cardíaca; `workout_reminder_service.dart` agenda lembretes locais. Esses recursos exigem permissões, suporte do sistema operacional e validação em aparelho compatível.
- **Segurança de tipos:** Dart verifica tipos e usa null safety para explicitar valores que podem não existir, como uma sessão não autenticada ou dados ainda não carregados. Isso ajuda a tratar estados incompletos antes que virem erros em tempo de execução.

Esses conceitos foram úteis porque o WeGYM combina telas com estado frequente (treinos e formulários), operações demoradas (API e sensores), diferentes tamanhos de tela e recursos próprios de celulares. Para explicar um fluxo na apresentação, mostre a tela, a ação do usuário, a atualização do estado em Dart e, quando aplicável, a chamada ao backend ou ao recurso do aparelho.

**Resumo para apresentar:** “Usamos Flutter e Dart para compartilhar a interface entre Web e dispositivos móveis. A tela é composta por widgets; os estados mudam com as interações do usuário; `async`/`await` conecta o app à API e aos sensores sem travar a interface; e `LayoutBuilder` adapta a navegação ao tamanho da tela. GPS, Bluetooth e notificações mostram a integração com recursos do dispositivo. O backend Next.js permanece responsável pelos serviços e dados compartilhados.”

### Integrantes e contribuições

Todos os integrantes devem participar da apresentação. Preencham a tabela com os nomes e as contribuições efetivamente realizadas pela equipe:

| Integrante | Contribuição no projeto | Parte apresentada |
| --- | --- | --- |
| [Nome do integrante 1] | [Telas, funcionalidades ou documentação desenvolvidas] | [Tópico que apresentará] |
| [Nome do integrante 2] | [Telas, funcionalidades ou documentação desenvolvidas] | [Tópico que apresentará] |
| [Nome do integrante 3] | [Telas, funcionalidades ou documentação desenvolvidas] | [Tópico que apresentará] |

Adicione ou remova linhas conforme o tamanho da equipe. Registre contribuições reais, inclusive planejamento, prototipação, implementação, integração, testes e documentação, conforme aplicável.

### Melhorias previstas

- Completar a comparação e os ajustes de fidelidade de todas as telas com o protótipo final.
- Validar autenticação, persistência e operações de cadastro, edição e exclusão com banco de dados configurado.
- Validar a integração Gemini e os serviços externos com credenciais reais, sem incluir chaves no repositório.
- Testar os fluxos em aparelhos Android/iOS e conferir acessibilidade, responsividade e estados sem conexão.
- Ampliar os testes automatizados e concluir a validação das integrações com hardware e provedores externos.

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
