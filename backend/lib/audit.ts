import { prisma } from './prisma';
import { logger } from './logger';

export type AuditAction =
  | 'user.login'
  | 'user.logout'
  | 'user.register'
  | 'user.delete_account'
  | 'user.update_profile'
  | 'user.export_data'
  | 'user.consent_change'
  | 'password.forgot_request'
  | 'password.reset'
  | 'payment.processed'
  | 'subscription.cancelled'
  | 'integration.connected'
  | 'integration.disconnected'
  | 'training_plan.created'
  | 'training_plan.deleted'
  | 'workout_session.created'
  | 'gps_session.created'
  | 'measurement.created'
  | 'checkin.created'
  | 'goal.created'
  | 'goal.deleted'
  | 'social.post_created'
  | 'social.comment_created'
  | 'social.like_toggled'
  | 'friend.request_sent'
  | 'friend.request_accepted'
  | 'message.sent'
  | 'challenge.joined'
  | 'appointment.booked'
  | 'appointment.cancelled'
  | 'athlete.registered_by_personal';

interface AuditLogParams {
  userId: string;
  action: AuditAction;
  metadata?: Record<string, unknown>;
  ip?: string;
}

export async function auditLog({ userId, action, metadata, ip }: AuditLogParams): Promise<void> {
  try {
    logger.info({ audit: { userId, action, ip, ...metadata } }, `[Audit] ${action}`);

    await prisma.auditLog.create({
      data: {
        userId,
        action,
        metadata: metadata ? JSON.stringify(metadata) : undefined,
        ip: ip ?? null,
      },
    });
  } catch (error) {
    logger.error({ err: error, action, userId }, 'Failed to write audit log');
  }
}
