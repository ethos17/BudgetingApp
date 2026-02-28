import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { JWT_EXPIRES_IN } from './auth.constants';
import { LoginDto } from './dto/login.dto';
import { SignupDto } from './dto/signup.dto';

export interface SafeUser {
  id: string;
  email: string;
  include_pending_in_budget: boolean;
  notify_on_pending: boolean;
  created_at: Date;
  updated_at: Date;
}

function toSafeUser(user: {
  id: string;
  email: string;
  include_pending_in_budget: boolean;
  notify_on_pending: boolean;
  created_at: Date;
  updated_at: Date;
}): SafeUser {
  return {
    id: user.id,
    email: user.email,
    include_pending_in_budget: user.include_pending_in_budget,
    notify_on_pending: user.notify_on_pending,
    created_at: user.created_at,
    updated_at: user.updated_at,
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async signup(dto: SignupDto): Promise<{ user: SafeUser; token: string }> {
    const password_hash = await argon2.hash(dto.password);
    try {
      const user = await this.prisma.user.create({
        data: {
          email: dto.email,
          password_hash,
        },
      });
      const token = this.jwtService.sign(
        { sub: user.id, email: user.email },
        { expiresIn: JWT_EXPIRES_IN },
      );
      return { user: toSafeUser(user), token };
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        throw new ConflictException({
          code: 'CONFLICT',
          message: 'Email is already registered',
        });
      }
      throw e;
    }
  }

  async login(dto: LoginDto): Promise<{ user: SafeUser; token: string }> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid email or password',
      });
    }
    const ok = await argon2.verify(user.password_hash, dto.password);
    if (!ok) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Invalid email or password',
      });
    }
    const token = this.jwtService.sign(
      { sub: user.id, email: user.email },
      { expiresIn: JWT_EXPIRES_IN },
    );
    return { user: toSafeUser(user), token };
  }

  async getMe(userId: string): Promise<SafeUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'User not found',
      });
    }
    return toSafeUser(user);
  }
}
