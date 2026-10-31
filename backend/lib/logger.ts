import pino from 'pino';

const isBrowser = typeof window !== 'undefined';

export const logger = pino({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  ...(isBrowser
    ? { browser: {} }
    : {
        transport:
          process.env.NODE_ENV !== 'production'
            ? { target: 'pino-pretty', options: { colorize: true } }
            : undefined,
      }),
  redact: {
    paths: [
      'req.headers.cookie',
      'req.headers.authorization',
      'body.password',
      'body.token',
      'body.cpf',
      'body.cref',
      'body.passwordHash',
    ],
    censor: '[REDACTED]',
  },
});
