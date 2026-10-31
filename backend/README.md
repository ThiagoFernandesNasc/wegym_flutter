# 🏋️‍♂️ Wegym

## Plataforma Inteligente de Treinos — Academia, Cardio e Performance

<p align="center">
  <img src="https://img.shields.io/badge/Next.js%16.2.9-000000?style=for-the-badge&logo=nextdotjs&logoColor=white" alt="Next.js"/>
  <img src="httpsimg.shields.io/badge/React%19.2.4-61DAFB?style=for-the-badge&logo=react&logoColor=black" alt="React"/>
  <img src="httpsimg.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript"/>
  <img src="httpsimg.shields.io/badge/Tailwind%20CSS%20v4-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white" alt="Tailwind CSS"/>
</p>

## 🎯 Transformando dados em resultados atléticos

O **Wegym** é uma plataforma completa de gestão e acompanhamento de treinos, desenvolvida para personal trainers, atletas e academias que buscam otimizar desempenho através de dados precisos e tecnologia avançada.

---

## ✨ Funcionalidades Principais

### 👤 Gestão de Usuários
- **Autenticação completa** com NextAuth.js (social e email/password)
- **Perfis diferenciados**: Atletas e Personal Trainers
- **Exportação de dados** em formato estruturado
- **Controle de consentimento** LGPD

### 🏋️‍♂️ Sistema de Treinos
- **Planos semanais** personalizáveis por dia
- **Controle de sessões** (início, pausa, retomada, finalização)
- **Múltiplas modalidades**: Academia, Corrida, Natação, Ciclismo, Caminhada
- **Histórico completo** de sessões por modalidade

### 📊 Painel Analytics
- **Estatísticas em tempo real**: sessões, tempo, distância, dias consecutivos
- **Gráficos de progresso** por modality
- **Rankings e conquistas** (gamification)
- **Métricas corporais** (IMC, peso, altura)

### 📱 Integrações Avançadas
- **GPS tracking** em tempo real para corridas e caminhadas outdoors
- **Integração Bluetooth** para monitoramento de frequência cardíaca
- **API MercadoPago** para pagamentos e assinaturas
- **Google Fit** integration for health data sync

### 🎨 Experiência do Usuário
- **Modais interativos** com IA para sugestão de planos de treino
- **Animações 3D** fluidas com Framer Motion
- **Interface responsiva** mobile-first
- ** modo escuro/claro** com preferência do sistema

---

## 🛠️ Tecnologias Utilizadas

| Categoria | Tecnologias |
|-----------|-------------|
| **Frontend** | Next.js 16.2.9 (App Router), React 19.2.4, TypeScript, Tailwind CSS v4, Framer Motion |
| **Backend** | Next.js Server Actions, API Routes, Prisma ORM |
| **Banco de Dados** | PostgreSQL via Prisma Client |
| **Autenticação** | NextAuth.js, JWT, OAuth (Google, GitHub possível) |
| **Estilização** | Tailwind CSS v4, CSS Modules, Custom Properties |
| **Animações** | Framer Motion 12, Lucide React |
| **Testes** | Vitest, React Testing Library |
| **Monitoramento** | Sentry (error tracking, performance monitoring) |
| **Deploy** | Vercel (configurado standalone output) |

---

## 📁 Estrutura de Pastas

```text
wegym/
├── app/                    # Next.js 16 App Router
│   ├── home/              # Página inicial com estatísticas
│   ├── profile/           # Perfil do usuário e configurações
│   ├── training/          # Página de treinos e sessões
│   ├── api/               # Rotas da API (auth, workout, payments)
│   ├── layout.tsx         # Layout raiz com metadata
│   └── globals.css        # Estilos globais + Tailwind v4
│
├── components/            # Componentes React reutilizáveis
│   ├── ui/                # Componentes UI genéricos (Tilt3D, Parallax, etc.)
│   ├── training/          # Componentes específicos de treino
│   ├── profile/           # Componentes de perfil do usuário
│   ├── login/             # Componentes de autenticação
│   └── integrations/      # Seções de integração de serviços
│
├── lib/                   # Bibliotecas e serviços utilitários
│   ├── services/          # Services layer (user, training, payment, etc.)
│   ├── cache.ts           # Sistema de cache em memória + Redis
│   ├── prisma.ts          # Configuração do Prisma Client
│   ├── redis.ts           # Conexão Redis
│   └── i18n/              # Internationalization hooks
│
├── prisma/                # Schema e migrações do banco de dados
│   ├── schema.prisma      # Definição de modelos Prisma
│   └── migrations/        # Histórico de migrações
│
├── mobile/                # Aplicação React Native (Expo + Router)
│   └── ...                # Código mobile separado
│
├── next.config.ts         # Configuração Next.js otimizada
├── package.json           # Scripts e dependências
└── tsconfig.json          # Configurações TypeScript
```

---

## ⚙️ Instalação e Execução Local

### 🔧 Pré-requisitos

- **Node.js**: Versão 18.x ou superior (recomendado: v20 LTS)
- **npm** ou **pnpm** ou **yarn**
- **Docker** (opcional, para containerização)
- **PostgreSQL** rodando localmente ou via serviço cloud

### 🚀 Passo a Passo

```bash
# 1. Clonar o repositório
git clone https://github.com/seu-usuario/wegym.git
cd wegym

# 2. Instalar dependências
npm install
# ou
pnpm install

# 3. Configurar variáveis de ambiente
cp .env.example .env
# Editar o arquivo .env com as credenciais necessárias (ver seção abaixo)

# 4. Executar migrações do banco de dados
npx prisma migrate dev --name init

# 5. Iniciar o servidor de desenvolvimento
npm run dev
# ou
pnpm dev

# A aplicação estará disponível em: http://localhost:3000
```

---

## 🌿 Variáveis de Ambiente (.env)

| Variável | Descrição | Obrigatória |
|----------|-----------|:-----------:|
| `NEXT_PUBLIC_SITE_URL` | URL base do site para metadata | ✅ |
| `NEXTAUTH_URL` | URL do próximo auth callback | ✅ |
| `NEXTAUTH_SECRET` | Segredo para sessões auth | ✅ |
| `DATABASE_URL` | String de conexão PostgreSQL | ✅ |
| `BCRYPT_ROUNDS` | Rodadas de hash de senha | ⚠️ |
| `MERCADO_PAGO_ACCESS_TOKEN` | Token de acesso MercadoPago | ✅ |
| `SENTRY_DSN` | DSN do Sentry para monitoramento | ⚠️ |
| `GOOGLE_AI_API_KEY` | Chave da API Google Generative AI | ⚠️ |

> ⚠️ = Variáveis opcionais que funcionalidades específicas dependem

### Exemplo `.env`:

```env
NEXT_PUBLIC_SITE_URL=https://wegym.com
NEXTAUTH_URL=https://wegym.com
NEXTAUTH_SECRET=sua-chave-secreta-muito-segura
DATABASE_URL=postgresql://user:password@localhost:5432/wegym
MERCADO_PAGO_ACCESS_TOKEN=TEST-....
SENTRY_DSN=https://o234567.ingest.sentry.io/87654321
```

---

## 📜 Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `npm run dev` | Inicia o servidor de desenvolvimento com Turbopack |
| `npm run build` | Cria a build de produção otimizada |
| `npm run start` | Inicia o servidor de produção (`next start`) |
| `npm run analyze` | Executa o bundle analyzer com `ANALYZE=true` |
| `npm run lint` | Roda o ESLint para verificação de código |
| `npm run lint:fix` | Corrige automaticamente os problemas do ESLint |
| `npm run test` | Executa o test suite com Vitest |
| `npm run test:watch` | Modo watch dos testes |
| `npm run db:push` | Push das mudanças do Prisma schema |
| `npm run db:migrate` | Executa migrações do banco de dados |
| `npm run docker:up` | Levanta os containers Docker |
| `npm run docker:down` | Para os containers Docker |

---

## 🚀 Instruções de Deploy

### 🌐 Vercel (Recomendado)

```bash
# 1. Conectar o repositório ao Vercel
# 2. O Vercel detectará automaticamente:
#    - Framework: Next.js 16.x
#    - Build command: next build
#    - Output directory: .next/standalone
#    - Framework settings configurados em next.config.ts

# 3. Variáveis de ambiente no painel Vercel:
#    - Adicionar todas as vars do .env na aba "Environment Variables"

# 4. Deploy automático a cada push na branch principal
```

### 🐳 Docker

```bash
# Build da imagem
docker build -t wegym .

# Rodar o container
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL} \
  -e NEXTAUTH_URL=${NEXTAUTH_URL} \
  -e NEXTAUTH_SECRET=${NEXTAUTH_SECRET} \
  -e DATABASE_URL=${DATABASE_URL} \
  -e MERCADO_PAGO_ACCESS_TOKEN=${MERCADO_PAGO_ACCESS_TOKEN} \
  wegym
```

### 📦 Produção Standalone

O projeto está configurado com `output: 'standalone'` no `next.config.ts`, o que gera uma saída otimizada para deploy em qualquer servidor Node.js:

```bash
# Após o build, os arquivos estarão em .next/standalone/
# Pode ser iniciado com: node .next/standalone/server.js
```

---

## 🤝 Contribuição

### 🍀 Pull Requests

1. **Fork** o repositório
2. **Crie uma branch** para sua feature: `git checkout -b feature/nova-funcionalidade`
3. **Commit** suas mudanças: `git commit -m 'feat: adiciona nova funcionalidade'`
4. **Push** para a branch: `git push origin feature/nova-funcionalidade`
5. **Abra um Pull Request** descrevendo o que foi feito e por quê

### 📋 Guidelines de Commit

Usamos convenção de commits [Conventional Commits](https://conventionalcommits.org/):

```
feat:  nova funcionalidade
fix:   correção de bug
docs:  alterações na documentação
style: formatação, missing semientes, etc.
refactor: refatoração de código
test:  adição de testes
chore: tarefas de manutenção trivial
```

---

## 📄 Licença

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contato

**Projeto Wegym** - https://wegym.com

**GitHub**: [@seu-usuario](https://github.com/seu-usuario)

**Desenvolvido com ❤️ por desenvolvedores full-stack**