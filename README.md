# WeGym Flutter

Cliente Flutter em `C:\Users\thiag\Downloads\wegym_flutter`. O backend oficial continua sendo o projeto Next.js original em `C:\Users\thiag\OneDrive\Documentos\WeGymFlutter\wegym`; o Flutter chama sua API e não substitui regras de negócio, autenticação ou persistência. A pasta `backend/` neste projeto Flutter é apenas uma cópia isolada para desenvolvimento.

## Executar o backend original

Em um terminal:

```powershell
cd C:\Users\thiag\OneDrive\Documentos\WeGymFlutter\wegym
npm run dev
```

Use o banco e as variáveis de ambiente já configurados no projeto original. O Next.js local normalmente atende na porta 3000.

## Executar o Flutter

```powershell
cd C:\Users\thiag\Downloads\wegym_flutter
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

No emulador Android, use `http://10.0.2.2:3000`. Em dispositivo físico, informe o IP local do computador. Para publicar, compile apontando para a URL HTTPS pública do backend:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://SEU-BACKEND
```

Não publique uma build que use `localhost`: o navegador de cada pessoa tentará acessar o próprio computador. A origem web publicada também precisa estar permitida no CORS do backend.

## Prévia visual

A prévia usa dados demonstrativos e não envia gravações ao servidor:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 7358 --dart-define=PREVIEW_DASHBOARD=true
```

## Migração e cobertura

Telas e fluxo de autenticação, dashboard, atividade, Workout Builder, comunidade, analytics, agendamentos, nutrição, alunos/personal, metas, programas, chat, perfil, assinatura e medidas estão presentes. Check-in, amigos e aulas foram adicionados e usam endpoints reais do Next.js. Ações de perfil incluem edição do nome, consentimento, exportação, OAuth, desconexão e exclusão da conta.

O comparativo detalhado, limitações e recursos pendentes estão em [MIGRATION_AUDIT.md](MIGRATION_AUDIT.md). Em especial, checkout com tokenização Mercado Pago, GPS contínuo, BLE, Apple Health/Health Connect, notificações push, armazenamento/sincronização offline e retorno de OAuth por deep link ainda exigem plugins, credenciais ou configuração nativa. Esses itens não são simulados como integrações funcionais.

## Verificação

```powershell
dart analyze lib
flutter build web --release --dart-define=API_BASE_URL=http://localhost:3000
```

Essas verificações confirmam análise estática e compilação; não substituem validação das rotas com banco e credenciais do ambiente real.
