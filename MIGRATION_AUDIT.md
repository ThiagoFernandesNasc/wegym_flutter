# Auditoria da migração Next.js para Flutter

Atualizada em 01/11/2026.

## Responsividade web e mobile

- A navegação e os painéis Flutter se reorganizam conforme a largura: barra lateral em janelas amplas e navegação inferior em celulares.
- `DeviceFramePreview` é opcional e mostra a interface em uma moldura de telefone no desktop, ativada pelo script `scripts/run_preview.ps1 -DeviceFrame`. Em celular real, o app permanece em tela inteira.
- O mesmo projeto Flutter oferece build web e alvos nativos Android/iOS. Integrações com recursos do aparelho podem ter suporte diferente por plataforma; BLE, GPS, notificações e pagamentos ainda têm validações específicas pendentes.

## Privacidade e perfil: exportação e exclusão

- Exportação consulta `GET /api/user/export`, serializa os dados como JSON e salva `dados-pessoais.json`; a prévia usa dados locais e não chama o backend.
- Exclusão exige digitar `EXCLUIR`, chama `DELETE /api/user/account` e encerra a sessão apenas após confirmação do backend.
- Testes cobrem o arquivo exportado, a rejeição de confirmação incorreta, a chamada de exclusão e o logout resultante.

## Identidade e instalação multiplataforma

- Web/PWA: `web/manifest.json` usa nome, cores, orientação adaptável e ícones WEGYM de 192/512 px. `web/index.html` define título, metadados e viewport para recortes de tela.
- Android e iOS: nomes de exibição e ícones nativos atualizados com o recurso WEGYM da referência.
- O APK não foi gerado no checkpoint inicial por falta do SDK; em 01/11/2026, com SDK/API 36 e NDK 28.2 instalados, `flutter build apk --debug --no-pub` concluiu.

## Verificação desta etapa de perfil e instalação

- Os atalhos de recursos e o resumo de plano no perfil usam a navegação principal e `GET /api/subscriptions/me`; os testes verificam os destinos e o plano ativo.
- `flutter analyze --no-pub` passou e `flutter test --no-pub` passou com 37 testes e 2 cenários de prévia ignorados.
- No checkpoint anterior, o build APK não iniciou porque faltava o SDK; após a instalação, `flutter doctor -v` reconhece o toolchain e o build debug passa.

- Os callbacks OAuth de Strava/Google Fit foram testados com troca de código simulada; `npm test` passou com 70 testes, `npx eslint` e `npx tsc --noEmit` passaram. Nenhuma credencial real foi usada.

## Projetos

- Flutter da apresentação: `C:\Users\thiag\Downloads\wegym_flutter`.
- Next.js de referência: `C:\Users\thiag\Downloads\wegym-master\wegym-master`.
- O backend Next.js permanece como serviço de dados; `backend/` no Flutter é uma cópia local de desenvolvimento.
- `API_BASE_URL`: padrão `localhost:3000` na web e `10.0.2.2:3000` no emulador Android. A cópia local restringe CORS a `http://localhost:7358` em desenvolvimento; em produção, configure `CORS_ALLOWED_ORIGIN` com a origem do app.
- Os arquivos `.env` não foram lidos nem alterados.

## Conferência da superfície da API e das páginas

- Comparação de `app/api/**/route.ts` entre a referência `wegym-master` e `backend/`: os 56 caminhos da referência têm correspondência local. A cópia local contém três rotas adicionais: `/auth/session`, `/payment-preference` e `/revalidate`.
- As páginas de login, recuperação/reset de senha, dashboard, treinos, estatísticas, medidas, Personal, check-in, conquistas, agenda, metas, nutrição, feed, chat, desafios, programas, pagamento, planos, perfil e documentos legais são atendidas pelos fluxos Flutter. As páginas com parâmetro, como desafios e programas, têm telas Flutter próprias.
- A rota Next `/offline` é uma página estática de contingência sem uso na navegação principal do original. No Flutter, a conectividade é apresentada no dashboard por um aviso de modo offline e pela fila/sincronização de treinos; não há uma rota Flutter `/offline` separada.

## Telas e fluxos

| Área | Estado no Flutter |
| --- | --- |
| Login, cadastro e recuperação de senha | Implementados com as rotas de autenticação disponíveis. |
| Termos de Uso e Política de Privacidade | Documentos navegáveis pelo cadastro/login e pelo perfil, com rolagem e retorno pela navegação; layout responsivo. |
| Dashboard, atividade e histórico | Dashboard usa perfil, estatísticas, sessões, plano e feed do backend; mostra modalidades favoritas com base no histórico e atalhos funcionais para musculação, corrida, ciclismo e aeróbico. Atividade continua ligada às sessões reais e cache local quando disponível. Os atalhos têm teste widget. |
| Treinos e editor | Criação e sessão presentes; sessões concluídas podem entrar na fila offline. |
| Assistente Gemini | Botão flutuante no layout compacto e em Treinos no layout amplo. No modo conectado, envia `message`/`level` ao `/api/chat` autenticado e apresenta exercícios estruturados; depende da chave Gemini no backend. Na prévia, mostra sugestões locais rotuladas como demonstração, sem chamar API, e permite iniciar uma sessão com os exercícios sugeridos. A resposta real do Gemini ainda depende de credenciais configuradas. |
| Comunidade, desafios e conquistas | Feed, publicação, curtidas, comentários e participação conectados aos endpoints. Na prévia, publicar, curtir e comentar atualizam o estado local sem chamadas ao servidor; participantes hipotéticos são identificados. O ranking de `/challenges/[id]` abre uma página Flutter responsiva e `/achievements` tem catálogo próprio. |
| Analytics e medidas | Períodos de 7 dias, 30 dias e 12 meses; seis indicadores calculados com dados do backend e gráfico de duração baseado em `chartData`. Sessões recentes e composição corporal em layout responsivo. Testes cobrem períodos e telas compactas/amplas. |
| Agenda e nutrição | Consultam e usam os endpoints disponíveis. Na prévia, criar plano/refeição, buscar e adicionar alimentos com recálculo local de macros e reservar, confirmar ou cancelar agendamento atualiza somente o estado local; testes confirmam que essas ações não chamam o backend. CRUD e persistência reais ainda precisam de validação com banco configurado. |
| Alunos e Personal | Listar, cadastrar, abrir ficha, consultar e registrar evolução física, editar e desvincular sem apagar a conta ou o histórico; usa /api/athletes/register, /api/athletes/[id] e /api/progress. Fluxo validado com API simulada; falta validar persistência com banco real. |
| Metas, programas e chat | Metas e mensagens conectadas; detalhes de `/programs/[id]` abrem uma página Flutter com exercícios agrupados por semana/dia e dados locais na prévia. |
| Perfil, assinatura e pagamento | Perfil e assinatura consultam o backend; a seleção mensal/anual abre o Checkout Pro hospedado. O backend valida o plano e define o preço, vincula a preferência à conta autenticada e envia notificação ao webhook público para ativar a assinatura. O retorno profundo ao app e a confirmação real em sandbox ainda precisam ser validados. |
| Check-in, amigos e aulas | Disponíveis no seletor de áreas. |
| GPS | Em primeiro plano, com pausa/retomada, percurso e envio por `/api/gps-sessions`. A tela Expo de referência pede permissão de segundo plano, mas usa `watchPositionAsync`, que também acompanha em primeiro plano; o rastreamento em segundo plano não faz parte do comportamento implementado no original. |
| Wearables BLE | Navegável em telas compactas e largas; busca o serviço Heart Rate (0x180D), mostra BPM/histórico e pode ler bateria. |
| Web e dispositivos móveis | Barra lateral em janelas amplas, navegação inferior em telas compactas e conteúdo ajustado à largura; moldura de telefone opcional na prévia. |

A presença de uma tela não confirma todos os fluxos de produção. Login externo, operações com dados reais e pagamentos dependem de configuração do backend e dos provedores.

## Modalidades de treino

- O editor agora abre sessões de natação, aeróbico e luta, além da musculação já existente; corrida, ciclismo, caminhada e trilha continuam no fluxo GPS.
- Sessões não GPS são cronometradas e salvas em `/api/workout-sessions`. Na natação, voltas e tamanho de piscina calculam a distância informada. Frequência cardíaca só é mencionada como disponível por sensor; o app não cria valores simulados.
- A tela de modalidades cobre salvamento via API e layouts compacto/amplo. flutter test --no-pub passou com 33 testes, 2 ignorados e nenhuma falha; dart analyze também passou.

## Divisão semanal de treinos

- O editor permite selecionar dias, distribuir divisões PPL, Upper/Lower, Full body, ABC e Bro split, e editar os exercícios por dia. No fluxo normal, o Personal seleciona um atleta e salva planos individuais pela API; o atleta consulta e altera o próprio plano.
- Na prévia, o Personal também consegue selecionar entre atletas fictícios. Planos e divisões ficam separados por atleta enquanto o editor está aberto; a demonstração inicia em um dia agendado e identifica os treinos em ordem (A, B, C), independentemente do dia da semana.
- Testes específicos cobrem PPL em dias diferentes, seleção e troca de atleta Personal e preservação local de uma divisão customizada. Outro teste verifica o contrato real de leitura/salvamento e a exclusão de um dia via API, com respostas controladas; também simula falha e repetição para garantir que o ID do plano não se perca antes de o DELETE confirmar. A persistência real ainda depende de banco configurado.

## Paridade do perfil

- O perfil Flutter agora edita nome, peso e altura usando `PATCH /api/user/profile`; para atletas, calcula o IMC a partir das medidas retornadas pelo backend. O perfil Personal mostra o CREF e não exibe campos físicos do atleta.
- Na prévia, essas mudanças são aplicadas somente ao estado local da demonstração. O backend gera `avatarPlaceholder`, agora apresentado no cabeçalho e na identidade do perfil com fallback para iniciais. O Next.js original não persiste a troca de foto: o botão apenas informa que o recurso será disponibilizado futuramente; o Flutter mantém essa mesma limitação de forma explícita.
- O original também oferece opções de instalação PWA, integrações de dispositivos e credenciais. BLE e Google Fit/Strava têm telas ou fluxos próprios no Flutter; validação OAuth com contas reais, upload persistente de avatar e validação do convite PWA em navegadores/dispositivos reais ainda estão pendentes. O perfil Flutter também apresenta o plano atual da rota `/api/subscriptions/me` e atalhos responsivos para metas, check-in, feed, chat, programas, nutrição, conquistas, desafios, agenda e evolução. O manifest web, os metadados e os ícones agora usam a marca WEGYM; o perfil usa `beforeinstallprompt` quando disponível e orienta sobre o menu do navegador nos demais casos.

## Retorno do Checkout Pro

- Preferências de pagamento nativas incluem retorno `wegym://payment-return`; Android e iOS declaram esse esquema e o Flutter captura links desde o início do app.
- A versão web envia `platform: web`; URLs de retorno são criadas somente a partir de `FLUTTER_APP_URL` HTTPS configurada no backend. Sem essa configuração, o checkout continua disponível e a interface informa que o retorno automático não foi configurado.
- Ao retornar, o app consulta `/api/subscriptions/me`; os parâmetros de retorno do provedor não são tratados como prova de pagamento. A confirmação sandbox ainda depende de credenciais e webhook reais.
- `app_links` foi adicionado para receber deep links nativos e URLs web. A moldura de dispositivo segue opcional; a navegação normal adapta-se a larguras amplas e compactas.

## Retorno OAuth de integrações

- A rota `/api/integrations` inclui a plataforma (`next`, `flutter_web` ou `flutter_native`) no `state` assinado; callbacks validam assinatura e provedor antes de salvar tokens.
- Após autorizar, web retorna a `FLUTTER_APP_URL`; Android/iOS retornam a `wegym://integration-return`. O Flutter atualiza o perfil e o status da integração ao receber o callback.
- O script de prévia define localmente `http://localhost:7358`. A validação com contas Google Fit/Strava reais ainda depende das credenciais em `backend/.env`.

## Offline e integrações nativas

- Perfil/estatísticas consultados podem ser carregados do armazenamento local.
- Treinos concluídos offline ficam vinculados à conta e sincronizam ao voltar à rede ou manualmente. A fila não cobre todas as operações nem resolve conflitos.
- GPS fica em primeiro plano, como o `watchPositionAsync` no app mobile de referência. Esse app pede permissão de segundo plano, mas não inicia rastreamento em background.
- BLE usa serviço padrão de frequência cardíaca. Na web, depende de Web Bluetooth, navegador/dispositivo compatível, contexto seguro e autorização do usuário. A compatibilidade varia entre navegadores; a conexão exige origem segura (HTTPS ou localhost) e permissão explícita. A documentação do plugin lista Android, iOS, Linux, macOS e web; Windows precisa de implementação adicional.
- BLE compila para web, mas não foi testado com sensor físico.
- Health Connect/Apple Health e lembrete local diário estão integrados no Flutter. A leitura inclui passos, frequência cardíaca média e em repouso, distância, calorias ativas, sono e treinos; treinos também podem ser gravados com autorização. A referência não registra o token Expo em um serviço remoto, portanto push remoto não é uma integração funcional comprovada a migrar.
- Google Fit e Strava agora usam state assinado com plataforma e retornam ao Flutter Web ou ao deep link nativo; os provedores reais ainda dependem de credenciais e validação em HTTPS. Passkey/biometria e Mercado Pago exigem SDKs/credenciais.

## Verificações desta atualização

- Retorno de pagamento: a suíte anterior do backend passou com 61 testes, TypeScript e ESLint dos arquivos alterados passaram; nesta verificação, dart analyze passou, a suíte Flutter passou com 33 testes (2 ignorados) e flutter build web --release --no-pub concluiu.

- `dart format`: aplicado aos arquivos Dart alterados.
- `flutter analyze --no-pub`: sem problemas após incluir a tela própria de conquistas.
- `flutter build web --release --no-pub`: concluído com as telas legais, ranking, detalhes de programa e desafios responsivos.
- `flutter build apk --debug --no-pub`: passou em 01/11/2026. Artefato: `build/app/outputs/flutter-apk/app-debug.apk` (156.676.488 bytes). SDK Android API 36, Build Tools 36.0.0 e NDK 28.2 instalados.
- flutter test --no-pub: 33 testes passaram, 2 cenários exclusivos da prévia foram ignorados e não houve falhas. A cobertura inclui integração da IA com sessão, checkout, conquistas, ranking, detalhes de programa, participação, documentos legais, layouts compacto/amplo, BLE, feed, metas e Personal. Os dois testes de prévia continuam precisando ser executados com PREVIEW_DASHBOARD=true; BLE nao foi testado com sensor físico.
- Backend: a suíte completa passou com 59 testes; ESLint e `tsc --noEmit` passaram. Para o Vitest, `DATABASE_URL` foi definida como URL descartável somente no processo antes da importação do Prisma; nenhum banco foi iniciado ou acessado. Não houve chamada real ao Mercado Pago.
- Os 56 handlers da API original existem no backend local; ele tem dois handlers extras (`auth/session` e `revalidate`). Foram restaurados os guards de acesso para evolução, planos, agendamentos e refeições, além da validação de criação de horários. O feed social voltou a filtrar amizades como no original. A rota `/api/workout-stats` mantém cache local.
- `backend/prisma/schema.prisma` e as nove migrations agora correspondem à referência; foi incluída a migration que amplia prescrições de exercício. Nenhuma migration foi aplicada a banco.
- ESLint dos arquivos alterados e `tsc --noEmit` do backend passaram. `npm test`: 59 testes passaram, incluindo controles de acesso, filtro do feed e Checkout Pro, com `DATABASE_URL` descartável somente no processo de teste; nenhum banco foi acessado e arquivos `.env` não foram lidos nem alterados.
- A rota local `backend/app/api/athletes/[id]/route.ts` continua idêntica à do original. Operações com dados reais ainda dependem de autenticação e banco configurados.

## Cadastro migrado

- Atletas cadastram CPF, CEP, cidade, estado, idade, sexo, altura, peso, nível de experiência e dados de saúde opcionais. O CEP consulta o ViaCEP e permite preenchimento manual quando a busca falha.
- Personais validam o CREF por `/api/cref/validate`; o cadastro só avança se o servidor aprovar o registro. Ambos os fluxos pedem confirmação de senha e enviam consentimento para os termos e a privacidade.
- Testes cobrem rejeição/aprovação do CREF, preenchimento dos dados do atleta e consulta/reserva de agenda ligada ao Personal. Layout responsivo segue coberto em larguras compactas e amplas.

## Verificação das ações locais da prévia

- Publicar, curtir e comentar no feed alteram o estado visível da demonstração sem chamar a API. A agenda permite reservar, confirmar e cancelar localmente; nutrição permite registrar refeição, criar plano e buscar/adicionar alimentos de demonstração com recálculo de calorias e macronutrientes.
- `flutter analyze --no-pub` passou sem avisos; `flutter test --no-pub` passou com 38 testes e 8 testes exclusivos de prévia ignorados. Com `PREVIEW_DASHBOARD=true`, os 8 testes de demonstração passaram e o teste que valida o backend real foi ignorado como esperado.
- Essas alterações são somente para a prévia. O modo normal mantém as chamadas às rotas do backend. A persistência e as regras de negócio reais ainda dependem do backend e do banco configurados.
- `flutter build apk --debug --no-pub` e `flutter build web --release --no-pub` concluíram nesta atualização. O build web exibiu apenas a recomendação opcional de testar o modo WASM.
- Após as correções de runtime do editor de treinos, análise completa, suíte normal (38 aprovados/8 exclusivos da prévia ignorados), suíte de prévia (8 aprovados), APK debug e build web release foram executados novamente e passaram. O teste adicional de contrato incluído depois passou na suíte regular.
- Nesta atualização, análise e ambas as suítes foram repetidas: 38 testes regulares passaram, 8 foram ignorados na suíte normal; 8 testes de prévia passaram e 1 teste de contrato real foi ignorado nessa configuração.
- Foi simulada uma falha transitória ao excluir um dia de treino: o primeiro salvamento reporta erro e o segundo repete a exclusão e conclui. APK debug e build web release foram novamente gerados com o código atualizado.

## Estado verificado em 01/11/2026

- A navegação Flutter contém os 20 módulos apresentados no menu do app original. O fallback `/offline` não tem página Flutter própria: o app oferece armazenamento local e fila de sincronização para treinos, com cobertura limitada às operações descritas acima.
- A suíte normal foi atualizada com dois testes de login da demonstração. Os testes verificam que os cartões abrem, respectivamente, as contas de atleta e Personal sem exigir o backend; eles rodam apenas com `PREVIEW_DASHBOARD=true`.
- A suíte focada na prévia passou com 10 testes e ignorou o teste de contrato que exige backend real. A análise Flutter e a suíte normal também passaram nesta execução.
- A cobertura automatizada não prova fidelidade visual integral nem persistência em produção. Continuam pendentes as validações com banco/credenciais reais, serviços de terceiros e dispositivos físicos indicadas em Próximos passos.

## Integrações nativas

- O perfil em Android/iOS oferece Health Connect ou Apple Health, pede autorização do usuário e lê passos, batimentos médios e em repouso, distância, calorias, sono e treinos dos últimos sete dias. No Android, reconhece a necessidade de instalar Health Connect; na web, Strava e Google Fit OAuth permanecem como integrações separadas.
- Treinos de musculação, natação, luta e outras modalidades podem ser gravados em Health Connect/HealthKit se a permissão de escrita tiver sido autorizada. Essa gravação é complementar: erros ou falta de autorização não impedem o salvamento principal no backend.
- Android declara permissões de leitura/escrita necessárias, consulta a disponibilidade do Health Connect e usa `FlutterFragmentActivity` para o fluxo de permissões. O plugin requer API 26+, então o `minSdk` Android foi elevado de 24 para 26. iOS declara HealthKit, textos de consentimento e deployment target 15.0.
- O perfil Android/iOS também tem um controle para lembrete local diário às 7h, igual ao horário padrão do app mobile de referência. O app pede permissão, agenda no fuso local do dispositivo, permite cancelar e recupera o agendamento após reinicialização Android. No Android usa alarme inexato para não pedir acesso a alarmes exatos. O navegador não agenda notificações repetidas; por isso o controle aparece somente nos apps nativos.
- A referência mobile obtém um token Expo, mas não o envia a uma API de registro nem configura entrega remota; o lembrete implementado nos dois clientes é local. Push remoto ainda não faz parte do fluxo comprovado do original nem desta migração.
- `flutter_local_notifications` e `flutter_timezone` foram adicionados. A configuração Android inclui desugaring, permissão de reinicialização e receivers de notificação; iOS usa as permissões locais do sistema.
- Validação desta etapa: `flutter analyze --no-pub` sem problemas; `flutter test --no-pub` com 41 testes aprovados e 10 cenários exclusivos da prévia ignorados; a suíte de prévia focada passou com 10 testes e 1 teste de contrato ignorado; `flutter build apk --debug --no-pub` e `flutter build web --release --no-pub` concluídos. O APK atual tem 160.096.283 bytes.
- Health Connect, notificações e BLE ainda precisam de teste em aparelhos físicos. O build iOS não pode ser validado neste Windows sem macOS/Xcode. A suíte automatizada não substitui esse teste nativo.

## Próximos passos

1. Configurar backend, `CORS_ALLOWED_ORIGIN`, chave Gemini e banco; validar login, geração por IA, CRUDs e persistência reais.
2. Comparar telas com Figma/Stitch e validar navegação/responsividade por perfil.
3. Testar BLE, Health Connect/Apple Health e lembrete local em aparelhos físicos; validar as telas com os nós Figma que ainda faltam comparar.
4. Validar Checkout Pro em sandbox com credenciais e webhook HTTPS; testar o retorno OAuth/deep links com contas reais dos provedores.
5. Validar Android em dispositivo ou emulador; SDK/API 36, Build Tools 36.0.0 e NDK 28.2 instalados; APK de depuração compilado. iOS requer macOS/Xcode.

## Verificação atualizada em 02/11/2026

- `flutter analyze --no-pub` passou sem problemas.
- `flutter test --no-pub` passou: 41 testes aprovados e 11 testes exclusivos da demonstração ignorados.
- `flutter test --no-pub --dart-define=PREVIEW_DASHBOARD=true` passou: 28 testes aprovados e 24 testes de fluxo conectado ignorados, pois usam fixtures de API em vez dos dados locais da demonstração. Os testes locais de login por perfil, participação em desafios, edição semanal de treinos e geração local de exercícios pela IA permaneceram ativos.
- O assistente na prévia foi compilado nos builds web release e Android debug; ambos concluíram com sucesso.
- As suítes verificam modos diferentes: a normal valida contratos de API simulados; a prévia valida o comportamento local sem persistência. A aprovação automatizada não substitui a validação com backend, banco, credenciais e dispositivos reais.
- Backend da cópia Flutter: `npm test` passou sem `.env` nem `DATABASE_URL` externa, com 70 testes em 14 arquivos; o setup define o fallback local de teste antes da importação das rotas. `npx tsc --noEmit` passou e ESLint passou nos endpoints/serviços ligados à API do app. O ESLint global ainda encontra erros e avisos no conjunto mais amplo de telas Next.js/Expo; isso permanece como pendência de qualidade fora dos arquivos de API verificados.
- Comparação das rotas Next.js: as 56 rotas da referência existem no backend empacotado, que tem ainda `/api/auth/session`, `/api/payment-preference` e `/api/revalidate`. Foram identificados 44 caminhos de API explícitos no código Flutter; todos correspondem a rotas do backend, exceto `/api/payment-preference`, implementada como extensão para Checkout Pro.

## Verificação do dashboard e Analytics em 02/11/2026

- O dashboard agora deriva as modalidades mais praticadas do histórico real e oferece atalhos conectados para musculação, GPS (corrida/ciclismo/caminhada) e sessões de aeróbico, natação ou luta. A navegação mantém o retorno e persiste a rota e a modalidade escolhida para restaurar a sessão multimodal após recarregar.
- Analytics mostra os períodos de 7 dias, 30 dias e 12 meses, seis métricas e o gráfico construído a partir do campo `chartData` já fornecido pelo backend.
- `flutter analyze --no-pub`: sem problemas. `flutter test --no-pub`: 44 aprovados e 11 ignorados. `flutter build web --release --no-pub`: concluído.

## Auditoria da agenda e alunos em 02/11/2026

- Alunos & Personal usa a paginação por cursor oferecida por `/api/athletes`, carrega as próximas páginas sem duplicar atletas e inclui um teste específico.
- A agenda diferencia os papéis conforme o contrato original: o atleta escolhe e reserva horários disponíveis; o Personal cria horários via `POST /api/appointments/slots`. A reserva não exige digitação manual do ID e o Personal não é registrado como atleta ao criar disponibilidade.
- Testes do Personal incluem cadastro, edição, desvinculação e carregamento da segunda página. Testes de agenda cobrem reserva do atleta e criação de horário pelo Personal.
- `flutter analyze --no-pub`: sem problemas. Suíte normal: 46 aprovados, 11 ignorados; suíte `PREVIEW_DASHBOARD=true`: 31 aprovados, 26 ignorados. Os ignorados são fluxos exclusivos do modo oposto.
- `flutter build web --release --no-pub`: concluído.
- Ainda falta validar a agenda com backend, banco e contas reais; os testes de UI usam respostas de API controladas.

## Verificação da IA de treino em 02/11/2026

- O Flutter envia `message` e `level` para `/api/chat`, campos aceitos pelo `chatSchema` do backend Next.js. A chave Gemini permanece somente no backend (`GEMINI_API_KEY`); o app não expõe segredo no cliente.
- Exercícios retornados em `workoutData.exercises` são convertidos para o formato da sessão Flutter. O teste integrado agora percorre resposta da API, exibição dos exercícios, ação “Iniciar treino sugerido” e abertura da sessão ativa.
- A referência Expo tem uma divergência no cliente de chat: ele envia `text` e tipa a resposta como `reply`, enquanto a rota existente espera `message` e retorna `text`. O Flutter segue o contrato da rota funcional para preservar a integração real do servidor.
- Teste direcionado de integração IA → sessão: aprovado. A chamada ao Gemini real ainda depende da chave `GEMINI_API_KEY` e não foi feita neste teste.

## Revisao do CRUD de amigos em 02/11/2026

- O `GET /api/friends` manteve o formato antigo por padrao; `?includeRequests=1` retorna amizades aceitas e solicitacoes recebidas/enviadas com o `friendshipId` correto.
- Convites Flutter podem ser feitos por e-mail. Aceitar ou rejeitar uma solicitacao envia a resposta para o backend, que confirma que o usuario autenticado e o destinatario; na previa, as alteracoes permanecem locais e identificadas como demonstracao.
- `flutter analyze --no-pub` passou; `flutter test --no-pub test/module_screens_test.dart` passou, incluindo o fluxo de convite e resposta.
- Os testes direcionados do backend passaram: 8 testes em 2 arquivos. `npx tsc --noEmit` e ESLint nos arquivos alterados tambem passaram.
- Limite: os testes usam API/banco simulados; ainda e necessario validar convites entre contas reais com o banco configurado.

## Verificacao completa apos integracao de amigos em 02/11/2026

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub`: 47 testes passaram; 11 cenarios exclusivos da previa foram ignorados neste modo.
- `flutter test --no-pub --dart-define=PREVIEW_DASHBOARD=true`: 31 testes passaram; 27 cenarios conectados foram ignorados neste modo.
- Backend: `npm test -- --reporter=dot` passou com 77 testes em 15 arquivos; `npx tsc --noEmit` passou.
- `flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:3000`: build concluido. Esse artefato aponta para localhost e serve para demonstracao local; uma publicacao precisa da URL HTTPS do backend.
- A previa de desenvolvimento permanece em `http://localhost:7358` com o backend em `http://localhost:3000`. Os processos locais nao comprovam persistencia em banco nem validam provedores externos com credenciais reais.
- `flutter build apk --debug --no-pub`: APK debug atualizado compilado com sucesso em `build/app/outputs/flutter-apk/app-debug.apk`. O Gradle exibiu avisos de XML do SDK (versao 4) e de API Java obsoleta no plugin Android do Geolocator; eles nao impediram a compilacao.

## Comparacao e estado do backend local em 02/11/2026

- O inventario do projeto Next.js original e da copia em `wegym_flutter/backend` encontrou 26 paginas em cada projeto e 56 rotas de API originais presentes na copia. A copia Flutter tem ainda tres rotas adicionais: `auth/session`, `payment-preference` e `revalidate`.
- Os caminhos correspondem, mas 48 arquivos de implementacao de rota diferem em conteudo; as diferencas devem ser avaliadas pelo contrato e pelos testes, nao substituidas em bloco, pois incluem ajustes da migracao Flutter.
- O backend local responde HTTP 200 em `/api/health`, mas reporta estado `degraded`: o PostgreSQL rejeitou a senha configurada (`28P01`). O arquivo `.env` nao foi aberto nem alterado. CRUD persistente e autenticacao real dependentes do banco continuam sem validacao neste ambiente.
- Auditoria estatica dos arquivos Dart identificou 44 formatos de caminho `/api/...`; todos correspondem a rotas existentes no backend. Operacoes de metas e progresso podem usar o ID no corpo, enquanto callbacks OAuth, webhook, CSRF e health nao sao chamados como operacoes diretas de tela.
- Conferencia estatica adicional de contratos: 40 pares metodo/caminho HTTP explicitos no Flutter (GET, POST, PATCH e DELETE) foram confrontados com os handlers Next.js; nenhum caminho estava ausente e nenhum metodo chamado faltava na rota correspondente. Chamadas com caminho calculado em variavel nao entram nessa contagem e permanecem cobertas pelos testes de tela/modulo.

## Fidelidade visual Stitch: cores e tipografia em 02/11/2026

- Os tokens de `lib/stitch_design_system.dart` conferem com `kinetic_obsidian/DESIGN.md` do pacote Stitch enviado: fundo `#131316`, sidebar `#0E0E11`, superficies `#1B1B1E`, `#1F1F22`, `#2A2A2D`, `#353438`, texto `#E4E1E6`, texto secundario `#E2BFB2`, laranja `#F66018`, verde `#4AE176` e azul `#4D8EFF`.
- O tema global Flutter ja referenciava Inter, mas nao tinha assets locais. Foram adicionadas Inter variavel/italica e JetBrains Mono variavel de Google Fonts; os cronometros de treino e atividade usam JetBrains Mono. Licencas SIL OFL 1.1 estao ao lado das fontes e listadas em `pubspec.yaml`.
- SHA-256: `Inter-Variable.ttf` `29160A80FF49DDCAB2C97711247E08B1FAB27A484A329CE8B813D820DC559031`; `Inter-Italic-Variable.ttf` `ACD98E64795781B2058F07B18475E0ECEE2A0FE2B42A49E2F9E37D0D6BF66CE6`; `JetBrainsMono-Variable.ttf` `48715A42EC242C21E9F02692891E147D022299A52E48D5E413E1A942193FFEDA`.
- Validacao apos a inclusao: `flutter analyze --no-pub` sem problemas; testes normais 47 aprovados/11 ignorados; testes da previa 31 aprovados/27 ignorados; builds web release e APK debug concluidos. A previa foi reiniciada e respondeu HTTP 200 para os arquivos Inter e JetBrains Mono.

## Painel Flutter: metas vinculadas ao backend em 02/11/2026

- O dashboard agora consulta `GET /api/goals?status=active` para atleta e Personal e mostra a meta ativa cadastrada, progresso, unidade e calorias mensais. O botao `VER METAS` abre a tela de metas (`onNavigate(8)`).
- Removido o alvo fixo de 22 treinos do indicador mensal. Quando nao existe meta ativa, o painel apresenta estado sem meta e oferece navegacao para criar/consultar metas, sem fabricar progresso.
- A previa usa uma meta local de demonstracao (12/16) dentro dos dados hipoteticos; ela nao e enviada ao backend.
- `flutter analyze --no-pub`: sem problemas. `flutter test --no-pub`: 47 aprovados e 11 exclusivos da previa ignorados. `flutter test --no-pub --dart-define=PREVIEW_DASHBOARD=true`: 31 aprovados e 27 cenarios conectados ignorados.
- `flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:3000`: concluido com codigo 0. A previa continua respondendo HTTP 200 em `http://localhost:7358`.
- O backend responde HTTP 200, mas `/api/health` reporta `degraded`: PostgreSQL rejeita a senha (`28P01`). Nao foi aberto nem alterado nenhum arquivo `.env`; consultas reais de metas e demais persistencia seguem dependendo da correcao dessa configuracao.
- Diferenca visual pendente: o Stitch pede volume semanal e ranking da unidade, que nao estao disponiveis como metricas reais no endpoint atual. `totalVolume` nesse backend representa segundos ativos; nao deve ser apresentado como carga levantada. A proxima etapa deve conferir se existe fonte persistida de cargas executadas antes de implementar esses indicadores.
## Registro de series e volume semanal confirmado em 02/11/2026

- Durante uma sessao de musculacao, cada serie prescrita pode ser marcada como concluida. O atleta confirma carga (kg) e repeticoes executadas; esses valores, com `completed: true`, seguem junto dos exercicios para `POST /api/workout-sessions`.
- A selecao da carga/repeticoes usa a prescricao como valor inicial editavel. Series nao confirmadas nao entram no volume. O controlador da sessao mantem os registros enquanto a navegacao troca de tela.
- O servico Next.js agora consulta o JSON dos exercicios e expoe `totalLiftedVolumeKg`, somando apenas series concluidas com carga/repeticoes numericas validas. O campo legado `totalVolume` continua mantendo o significado anterior de segundos para nao quebrar consumidores existentes.
- O card `VOLUME SEMANAL` do Flutter usa esse novo campo e exibe `SÉRIES CONFIRMADAS`; sessoes antigas sem o novo historico contribuem com zero carga rastreada. O projeto original em `wegym-master` permaneceu somente leitura.
- Cobertura: teste Flutter registra uma serie de 80 kg por 9 repeticoes e verifica o payload; teste do servico confirma que apenas series concluidas somam 1.520 kg. Testes direcionados Flutter passaram.
- `flutter analyze --no-pub`: sem problemas; testes completos Flutter: 48 aprovados/11 ignorados no modo conectado e 32 aprovados/27 ignorados na previa; backend: 78 testes aprovados; `npx tsc --noEmit` e ESLint dos dois arquivos alterados passaram.
- `flutter build web --release --no-pub --dart-define=API_BASE_URL=http://localhost:3000`: concluido. A validacao de persistencia real continua pendente da senha PostgreSQL (`28P01`) e da configuracao `.env`, que permanece sem ser aberta ou alterada.
- A previa local foi semeada com `totalLiftedVolumeKg: 38450` para reproduzir o cartao Stitch; o banner de demo identifica esses dados como hipoteticos e nenhuma serie e enviada ao servidor.
- A comparacao dos schemas Prisma original/copia nao encontrou modelo nem chave de academia/unidade. O ranking `RANK NA UNIDADE` continua sem fonte de dados; manter `DISTANCIA` (real) e preferivel a inventar um rank. Para implementar ranking por unidade seria necessario primeiro modelar unidades e vinculos reais.

## Consentimentos explicitos no cadastro (02/11/2026)

- O Flutter apresenta caixas independentes para Termos de Uso, Politica de Privacidade e tratamento de dados, e impede o envio do cadastro sem as tres confirmacoes.
- O cadastro envia `termsAccepted`, `privacyAccepted` e `dataConsentAccepted`; o schema do backend valida o novo campo quando informado e continua aceitando clientes existentes que ainda nao o enviam.
- O teste de cadastro verifica os tres valores; o teste do schema confirma que `false` e rejeitado.


## Onboarding de primeiro acesso (02/11/2026)

- O Flutter agora exibe o tutorial por etapas apos o cadastro e no primeiro login; os conteudos sao especificos para atleta e Personal, com opcoes de avancar e pular.
- A conclusao fica salva no armazenamento seguro local, para evitar reapresentar o tutorial. O papel usado no login conectado vem do objeto `user.role` retornado pela API, nao do seletor de interface.
- Testes cobrem os dois conteudos, persistencia da conclusao, retorno do papel da API e exibicao apos cadastro. A compilacao APK debug tambem passou.

## Copilot contextual para Personal (02/11/2026)

- A area de gestao de alunos oferece o Copilot geral e, na ficha individual, um atalho que leva o nome e o nivel do atleta ao contexto da pergunta.
- No modo conectado, o cliente usa a rota existente `POST /api/chat` com o prefixo `[Personal Coach]`; a resposta textual e os exercicios estruturados sao apresentados. Erros de configuracao Gemini/backend sao expostos sem fingir uma resposta real.
- Na previa, o painel informa que a resposta e demonstrativa e nao envia a pergunta ao servidor.
- `flutter analyze --no-pub` passou sem avisos. A suite completa conectada passou com 55 testes e 12 cenarios de previa ignorados; a suite completa `PREVIEW_DASHBOARD=true` passou com 39 testes e 28 cenarios conectados ignorados. O teste contextual valida o payload enviado a `/api/chat` e o teste da previa confirma resposta local sem chamada ao backend.
## Revisao ortografica e compilacao final de apresentacao (02/11/2026)

- Corrigi texto que havia sido gravado com bytes UTF-8 interpretados como Windows-1252 no login, acessos demonstrativos, navegação, histórico e dashboard. Os dados de teste de conquistas também voltaram a usar os emojis de atleta e troféu corretamente.
- O teste de login demonstrativo agora ignora explicitamente o tutorial de primeiro acesso antes de validar o destino para atleta ou Personal.
- Verificação final do código: `flutter analyze --no-pub` sem problemas; suíte conectada: 55 aprovados/12 ignorados; suíte `PREVIEW_DASHBOARD=true`: 39 aprovados/28 ignorados. O teste específico do catálogo de conquistas passou após a correção dos emojis.
- `flutter build web --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true --dart-define=API_BASE_URL=http://localhost:3000` concluiu em 49,1 segundos. O bundle está em `build/web` e usa contas demonstrativas locais, sem exigir a configuração do `.env` para o fluxo de apresentação.- `flutter build apk --debug --no-pub` também concluiu; APK atualizado em `build/app/outputs/flutter-apk/app-debug.apk`.

## Perfil e avatar (02/11/2026)

- O endpoint de perfil ja fornece `avatarPlaceholder`; o Flutter agora o reutiliza no cabecalho e na secao de identidade, com fallback para a inicial se a URL estiver ausente ou falhar.
- O cartao mostra nome, e-mail, papel e informacoes compativeis com atleta ou Personal. O controle de foto explica que a troca ainda nao esta disponivel, igual ao comportamento do Next.js; nenhum upload persistente foi inventado.
- Um teste widget verifica identidade, fallback e mensagem do controle de foto. `flutter analyze --no-pub` passou; suite conectada: 56 aprovados/12 ignorados; suite de demonstracao: 39 aprovados/29 ignorados.
- `flutter build web --release --no-pub --dart-define=PREVIEW_DASHBOARD=true --dart-define=PREVIEW_REQUIRE_LOGIN=true --dart-define=API_BASE_URL=http://localhost:3000` e `flutter build apk --debug --no-pub` concluiram apos essa alteracao.

## Inicializacao resiliente da previa (02/11/2026)

- No modo de demonstracao com login obrigatorio, a tela de entrada agora e liberada mesmo se o navegador rejeitar a limpeza do armazenamento seguro; antes, essa excecao podia manter a inicializacao aguardando.
- A previa reiniciada responde em `http://localhost:7358`; o fluxo de login foi validado para atleta e Personal. Analise Flutter sem problemas.
- O health check do backend permanece degradado por autenticacao PostgreSQL `28P01`; a senha em `.env` nao foi alterada. A verificacao visual no Brave depende de confirmar se o login voltou a aparecer.

## Feedback visual de carregamento Web (02/11/2026)

- `web/index.html` agora usa o fundo escuro da marca e mostra um indicador de inicializacao; o indicador some no evento `flutter-first-frame` do Flutter Web. Se o primeiro quadro demorar mais de 15 segundos, a mensagem orienta a verificar o terminal.
- `flutter build web --release --no-pub` com os defines de demonstracao concluiu. A pre-visualizacao na porta 7358 responde HTTP 200 e serve a nova marcacao.

## Cobertura CRUD de metas (02/11/2026)

- A tela de metas do Next original permite criar uma meta e marcar o progresso como concluido. O Flutter tambem oferece editar progresso e excluir, mantendo as mesmas rotas de metas.
- Um teste de fluxo completo agora percorre criacao, atualizacao, conclusao com confirmacao e exclusao, verificando corpo HTTP e identificadores. Analise limpa; suite conectada: 57 aprovados/12 ignorados; demonstracao: 39 aprovados/30 ignorados.

## Contratos de API revisados

- A varredura encontrou 44 familias de endpoints chamadas pelo Flutter; elas estao presentes na copia Next.js em `backend/`, incluindo rotas dinamicas quando normalizadas.
- O checkout Flutter usa adicionalmente `POST /api/payment-preference`, implementado na copia backend para Checkout Pro hospedado. O Next de referencia tem `/api/process-payment`, que recebe token de cartao do SDK web; ambos usam Mercado Pago, mas o contrato e o fluxo visual diferem. A confirmacao de pagamento continua dependente de credenciais e webhook de sandbox/HTTPS reais.

## Atualizacao do artefato Android (02/11/2026)

- `flutter build apk --debug --no-pub` concluiu apos a protecao da inicializacao do modo demonstracao.
- APK atualizado em `build/app/outputs/flutter-apk/app-debug.apk`.
- Revisao do original confirmou que `authOptions` registra apenas `CredentialsProvider`; os botoes Google/Apple/passkey presentes no Figma sao elementos visuais sem OAuth/passkey funcional no Next original. O mapa de migracao agora explicita essa diferenca.

## APK de demonstracao para apresentacao (02/11/2026)

- O APK release foi compilado com `PREVIEW_DASHBOARD=true` e `PREVIEW_REQUIRE_LOGIN=true`, preservando a selecao de login atleta/Personal e dados locais de demonstracao.
- Artefato: `build/app/outputs/flutter-apk/app-release.apk` (57,3 MB). O APK debug tem cerca de 185 MB e serve para desenvolvimento.
- `flutter devices` encontrou apenas Windows e Edge; nao ha AVD nem aparelho Android conectado neste ambiente. O APK compilou, mas ainda falta instalar e validar a interacao em um dispositivo real/emulador.
