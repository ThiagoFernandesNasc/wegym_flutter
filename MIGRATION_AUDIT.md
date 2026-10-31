# Auditoria da migração Next.js → Flutter

Data da comparação: 30/10/2026.

## Arquitetura

- O projeto de referência e backend é o Next.js em `C:\Users\thiag\OneDrive\Documentos\WeGymFlutter\wegym`.
- O cliente Flutter fica em `C:\Users\thiag\Downloads\wegym_flutter`.
- A Flutter API usa `API_BASE_URL`; sem configuração, aponta para `localhost:3000` na web e `10.0.2.2:3000` no emulador Android. Para dispositivo físico ou produção, informe o endereço HTTPS público do Next.js.
- A pasta `backend/` presente dentro do cliente Flutter é cópia de desenvolvimento. Ela não é a fonte oficial nem deve ser publicada como substituta do Next.js original.

## Cobertura de interface e fluxos

| Área do Next.js / app mobile | Flutter | Estado |
| --- | --- | --- |
| Login, cadastro, recuperar senha | Login e cadastro; pedido de recuperação e redefinição com token | Conectado aos endpoints de autenticação existentes |
| Dashboard, histórico/atividade, sessão de treino | Dashboard, histórico e Workout Builder | Fluxos principais conectados a estatísticas, sessões e planos |
| Comunidade, desafios, conquistas | Comunidade, desafios, ranking e ações de publicação/curtida/comentário | Conectado aos endpoints social/challenges/achievements |
| Analytics, medidas corporais | Analytics e medidas com registro de peso | Conectado aos endpoints existentes |
| Agendamentos, nutrição, alunos/personal, metas, programas, chat | Telas presentes | Consultas e ações usam os endpoints existentes, mas parte da experiência ainda é genérica e precisa de revisão tela a tela no Figma |
| Perfil, integrações, LGPD | Edição de nome, consentimentos, exportação, desconexão/exclusão de conta e início de OAuth | Ações enviadas ao Next.js; OAuth retorna URL para autorização. Fluxo de retorno profundo para o app ainda não está implementado |
| Check-in, amigos e aulas | Telas adicionadas ao seletor “Mais” | Consultas e gravação de check-in/solicitação de amizade ligadas às rotas Next.js |
| Assinatura/pagamento | Consulta de assinatura presente | Checkout Flutter ainda incompleto: a API de pagamento exige tokenização de cartão do Mercado Pago, SDK/configuração segura não implementados no Flutter |

## Integrações ainda não migradas

O app Expo do projeto original contém recursos nativos que não são substituídos por uma tela Flutter: rastreamento GPS em segundo plano, Bluetooth/BLE, Apple Health/Health Connect, notificações push, armazenamento e sincronização offline. Cada um requer plugin Flutter, permissões e configuração nativa Android/iOS, além de chaves/credenciais para serviços externos. A API Next.js continua preservada e não foi alterada nesta migração.

Também precisam de tratamento específico: OAuth com retorno ao app por deep link; login Google/Apple e passkey/biometria; tokenização de pagamento com o SDK Mercado Pago; CRUD completo de alunos e de agenda; fidelidade visual final de cada tela contra o Figma/Stitch.

## Verificação feita

- `dart analyze lib`: sem erros; permanecem avisos informativos de estilo no código existente.
- `flutter build web --release --dart-define=API_BASE_URL=http://localhost:3000`: compilação concluída e artefato `build/web/index.html` gerado.
- Não foram executados testes automatizados ou chamadas com gravação contra o banco real.
