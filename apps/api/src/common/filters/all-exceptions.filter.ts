import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { Prisma } from '@prisma/client';

interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly httpAdapterHost: HttpAdapterHost) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const { httpAdapter } = this.httpAdapterHost;
    const ctx = host.switchToHttp();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL';
    let message = 'An unexpected error occurred';
    let details: unknown;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();
      if (typeof res === 'object' && res !== null) {
        const r = res as Record<string, unknown>;
        code = (r.code as string) ?? this.codeFromStatus(status);
        message = (r.message as string) ?? exception.message;
        if (Array.isArray(r.message)) {
          message = 'Validation failed';
          details = { fields: r.message };
          code = 'VALIDATION_ERROR';
          status = HttpStatus.BAD_REQUEST;
        } else if (r.details !== undefined) {
          details = r.details;
        }
      } else {
        message = String(res);
        code = this.codeFromStatus(status);
      }
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') {
        status = HttpStatus.CONFLICT;
        code = 'CONFLICT';
        message = 'A record with this value already exists';
        details = { meta: exception.meta };
      } else {
        status = HttpStatus.BAD_REQUEST;
        code = `PRISMA_${exception.code}`;
        message = 'A database error occurred';
        details = { code: exception.code, meta: exception.meta };
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      code = exception.name || code;
    }

    const responseBody: ErrorResponse = {
      error: { code, message },
    };
    if (details !== undefined) {
      responseBody.error.details = details;
    }

    httpAdapter.reply(ctx.getResponse(), responseBody, status);
  }

  private codeFromStatus(status: number): string {
    const map: Record<number, string> = {
      [HttpStatus.BAD_REQUEST]: 'BAD_REQUEST',
      [HttpStatus.UNAUTHORIZED]: 'UNAUTHORIZED',
      [HttpStatus.FORBIDDEN]: 'FORBIDDEN',
      [HttpStatus.NOT_FOUND]: 'NOT_FOUND',
      [HttpStatus.CONFLICT]: 'CONFLICT',
    };
    return map[status] ?? 'INTERNAL';
  }
}
