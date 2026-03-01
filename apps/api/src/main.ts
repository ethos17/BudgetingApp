import * as path from 'path';
import { ValidationPipe } from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { NestFactory } from '@nestjs/core';
import cookieParser from 'cookie-parser';
import { config as loadEnv } from 'dotenv';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { validatePlaidEnv } from './plaid/plaid.config';

// Load apps/api/.env so env vars are available before Nest and when running from repo root
const envPath = path.join(__dirname, '..', '.env');
loadEnv({ path: envPath });

async function bootstrap() {
  validatePlaidEnv();
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');

  const corsOrigin = process.env.CORS_ORIGIN ?? true;
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
  });

  app.use(cookieParser(process.env.CSRF_SECRET ?? 'ledgerlens-default-secret'));

  const httpAdapterHost = app.get(HttpAdapterHost);
  app.useGlobalFilters(new AllExceptionsFilter(httpAdapterHost));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`LedgerLens API listening on port ${port}`);
}

bootstrap();

