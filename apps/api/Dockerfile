FROM node:20-alpine AS base

WORKDIR /usr/src/app

ENV NODE_ENV=production

COPY package.json ./
COPY tsconfig.json nest-cli.json ./
COPY prisma ./prisma
COPY src ./src

RUN npm install
RUN npx prisma generate --schema=./prisma/schema.prisma
RUN npm run build

EXPOSE 3000

CMD ["sh", "-c", "npx prisma migrate deploy --schema=./prisma/schema.prisma && node dist/main.js"]

