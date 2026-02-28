# LedgerLens

Budgeting app backend (NestJS + Prisma + Postgres).

## Backend

### Prerequisites

- Node 18+ (pnpm recommended: `corepack enable && corepack prepare pnpm@9 --activate`)
- Docker (for Postgres) or local Postgres

### Setup

1. From repo root, install dependencies:

   ```bash
   pnpm install
   ```

2. Copy env and set `DATABASE_URL` and `JWT_SECRET`:

   ```bash
   cp apps/api/.env.example apps/api/.env
   ```

3. Run migrations (with Postgres running, e.g. `docker compose up -d postgres`):

   ```bash
   pnpm -C apps/api prisma migrate dev
   ```

4. Seed the database (creates demo user):

   ```bash
   pnpm -C apps/api prisma db seed
   ```

### Run the API

```bash
pnpm -C apps/api start:dev
```

Or from root: `pnpm dev:api` (if configured in root `package.json`).

API runs at `http://localhost:3000` by default.

### Demo login

- **Email:** `demo@ledgerlens.local`  
- **Password:** `Password123!`

Example:

```bash
curl -c cookies.txt -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@ledgerlens.local","password":"Password123!"}'
```

Then call the current user endpoint with the stored cookie:

```bash
curl -b cookies.txt http://localhost:3000/me
```

Without the cookie, `GET /me` returns `401` with `error.code` `UNAUTHORIZED`.
