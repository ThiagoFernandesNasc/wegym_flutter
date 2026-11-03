import { prisma } from '@/lib/prisma';
import type { Prisma } from '@prisma/client';
import crypto from 'crypto';

const SECRET_KEY = process.env.TOKEN_ENCRYPTION_KEY || 'wegym-token-secret-key-change-in-production';

function encrypt(text: string): string {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(SECRET_KEY.padEnd(32, '0').slice(0, 32)), iv);
  const encrypted = Buffer.concat([cipher.update(text), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
}

function decrypt(encrypted: string): string {
  const [ivHex, authTagHex, encryptedHex] = encrypted.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');
  const encryptedBytes = Buffer.from(encryptedHex, 'hex');
  const decipher = crypto.createDecipheriv('aes-256-gcm', Buffer.from(SECRET_KEY.padEnd(32, '0').slice(0, 32)), iv);
  decipher.setAuthTag(authTag);
  const decrypted = Buffer.concat([decipher.update(encryptedBytes), decipher.final()]);
  return decrypted.toString('utf8');
}

type ProviderType = 'strava' | 'google_fit';

export const integrationService = {
  async getIntegrations(userId: string) {
    return prisma.integration.findMany({
      where: { userId },
      select: {
        id: true,
        provider: true,
        enabled: true,
        syncEnabled: true,
        lastSyncAt: true,
        createdAt: true,
        providerData: true,
      },
    });
  },

  async getIntegration(userId: string, provider: ProviderType) {
    const integration = await prisma.integration.findUnique({
      where: { userId_provider: { userId, provider } },
    });
    if (!integration) return null;
    return {
      ...integration,
      accessToken: integration.accessToken ? decrypt(integration.accessToken) : null,
      refreshToken: integration.refreshToken ? decrypt(integration.refreshToken) : null,
    };
  },

  async saveTokens(
    userId: string,
    provider: ProviderType,
    data: {
      accessToken: string;
      refreshToken?: string;
      tokenType?: string;
      expiresAt?: Date;
      scope?: string;
      providerData?: Prisma.InputJsonValue;
    },
  ) {
    return prisma.integration.upsert({
      where: { userId_provider: { userId, provider } },
      create: {
        userId,
        provider,
        accessToken: encrypt(data.accessToken),
        refreshToken: data.refreshToken ? encrypt(data.refreshToken) : null,
        tokenType: data.tokenType,
        expiresAt: data.expiresAt,
        scope: data.scope,
        providerData: (data.providerData ?? {}) as Prisma.InputJsonValue,
      },
      update: {
        accessToken: encrypt(data.accessToken),
        refreshToken: data.refreshToken ? encrypt(data.refreshToken) : null,
        tokenType: data.tokenType,
        expiresAt: data.expiresAt,
        scope: data.scope,
        providerData: (data.providerData ?? {}) as Prisma.InputJsonValue,
      },
    });
  },

  async updateLastSync(userId: string, provider: ProviderType) {
    return prisma.integration.update({
      where: { userId_provider: { userId, provider } },
      data: { lastSyncAt: new Date() },
    });
  },

  async setEnabled(userId: string, provider: ProviderType, enabled: boolean) {
    return prisma.integration.update({
      where: { userId_provider: { userId, provider } },
      data: { enabled },
    });
  },

  async disconnect(userId: string, provider: ProviderType) {
    await prisma.integration.delete({
      where: { userId_provider: { userId, provider } },
    });
  },
};
