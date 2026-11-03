import { NextResponse } from 'next/server';
import { chatService } from '@/lib/services/chat.service';
import { authenticate, getIP, handleError, withRateLimit } from '@/lib/api-utils';
import { chatSchema } from '@/lib/validation';
import { AppError, ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export const maxDuration = 60;

export async function POST(request: Request) {
  try {
    const localPreviewAI =
      process.env.NODE_ENV !== 'production' &&
      process.env.WEGYM_PREVIEW_AI_ENABLED === 'true' &&
      request.headers.get('x-wegym-preview-ai') === 'true';
    const session = localPreviewAI
      ? { user: { id: `local-preview:${getIP(request)}` } }
      : await authenticate();
    const rateLimitResponse = await withRateLimit(
      request,
      `chat:${session.user.id}`,
    );
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = chatSchema.safeParse(body);
    if (!parsed.success) {
      throw new ValidationError('Mensagem inválida', parsed.error.issues);
    }

    if (!process.env.GEMINI_API_KEY) {
      throw new AppError(503, 'AI_NOT_CONFIGURED', 'O assistente de IA ainda não está configurado. Não foi possível gerar o treino.');
    }

    const result = await chatService.generateWorkout(
      parsed.data.message,
      parsed.data.level ?? 'Iniciante',
    );

    return NextResponse.json(result);
  } catch (error) {
    return handleError(error);
  }
}
