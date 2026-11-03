import { describe, it, expect } from 'vitest';
import { registerSchema, athleteRegisterSchema, paymentSchema, emailSchema, cpfSchema, checkoutPreferenceSchema } from '@/lib/validation';

describe('emailSchema', () => {
  it('should validate correct emails', () => {
    expect(emailSchema.parse('Test@Example.com')).toBe('test@example.com');
  });

  it('should reject invalid emails', () => {
    const result = emailSchema.safeParse('not-an-email');
    expect(result.success).toBe(false);
  });
});

describe('cpfSchema', () => {
  it('should normalize CPF with mask', () => {
    expect(cpfSchema.parse('123.456.789-01')).toBe('12345678901');
  });

  it('should reject invalid length', () => {
    const result = cpfSchema.safeParse('123');
    expect(result.success).toBe(false);
  });
});

describe('registerSchema', () => {
  it('accepts explicit data consent and rejects an explicit refusal', () => {
    const registration = {
      email: 'consent@example.com',
      password: '12345678',
      userType: 'atleta' as const,
      name: 'Atleta Teste',
      termsAccepted: true as const,
      privacyAccepted: true as const,
    };

    expect(
      registerSchema.safeParse({ ...registration, dataConsentAccepted: true })
        .success,
    ).toBe(true);
    expect(
      registerSchema.safeParse({ ...registration, dataConsentAccepted: false })
        .success,
    ).toBe(false);
  });
  it('should validate a complete athlete registration', () => {
    const result = registerSchema.safeParse({
      email: 'test@example.com',
      password: '12345678',
      userType: 'atleta',
      name: 'João Teste',
      termsAccepted: true,
      privacyAccepted: true,
    });
    expect(result.success).toBe(true);
  });

  it('should reject missing terms acceptance', () => {
    const result = registerSchema.safeParse({
      email: 'test@example.com',
      password: '12345678',
      userType: 'atleta',
      name: 'João Teste',
    });
    expect(result.success).toBe(false);
  });

  it('should reject invalid userType', () => {
    const result = registerSchema.safeParse({
      email: 'test@example.com',
      password: '12345678',
      userType: 'admin',
      name: 'João Teste',
      termsAccepted: true,
      privacyAccepted: true,
    });
    expect(result.success).toBe(false);
  });

  it('should validate a personal trainer registration with CREF', () => {
    const result = registerSchema.safeParse({
      email: 'personal@example.com',
      password: '12345678',
      userType: 'personal',
      name: 'Prof. Teste',
      cref: '123456-G/SP',
      termsAccepted: true,
      privacyAccepted: true,
    });
    expect(result.success).toBe(true);
  });
});

describe('athleteRegisterSchema', () => {
  it('should validate athlete data', () => {
    const result = athleteRegisterSchema.safeParse({
      email: 'atleta@example.com',
      name: 'Maria',
      cpf: '123.456.789-01',
      sex: 'feminino',
      heightCm: 165,
      weightKg: 60,
      experienceLevel: 'intermediario',
      cep: '01001000',
      city: 'São Paulo',
      state: 'SP',
    });
    expect(result.success).toBe(true);
  });

  it('should reject invalid state', () => {
    const result = athleteRegisterSchema.safeParse({
      email: 'atleta@example.com',
      name: 'Maria',
      cpf: '12345678901',
      sex: 'feminino',
      heightCm: 165,
      weightKg: 60,
      experienceLevel: 'intermediario',
      cep: '01001000',
      city: 'São Paulo',
      state: 'XYZ',
    });
    expect(result.success).toBe(false);
  });
});

describe('paymentSchema', () => {
  it('should validate payment data', () => {
    const result = paymentSchema.safeParse({
      transaction_amount: 99.90,
      token: 'card_token_123',
      installments: 1,
      payment_method_id: 'visa',
      payer: { email: 'payer@example.com' },
    });
    expect(result.success).toBe(true);
  });

  it('should reject negative amount', () => {
    const result = paymentSchema.safeParse({
      transaction_amount: -10,
      token: 'card_token_123',
      installments: 1,
      payment_method_id: 'visa',
      payer: { email: 'payer@example.com' },
    });
    expect(result.success).toBe(false);
  });
});

describe('checkoutPreferenceSchema', () => {
  it('accepts only the supported WeGYM subscription plans', () => {
    expect(checkoutPreferenceSchema.parse({ planId: 'mensal' })).toEqual({
      planId: 'mensal',
      platform: 'native',
    });
    expect(checkoutPreferenceSchema.parse({ planId: 'anual' })).toEqual({
      planId: 'anual',
      platform: 'native',
    });
    expect(
      checkoutPreferenceSchema.parse({ planId: 'mensal', platform: 'web' }),
    ).toEqual({ planId: 'mensal', platform: 'web' });
    expect(checkoutPreferenceSchema.safeParse({ planId: 'custom', amount: 0.01 }).success).toBe(false);
    expect(
      checkoutPreferenceSchema.safeParse({ planId: 'mensal', platform: 'desktop' }).success,
    ).toBe(false);
  });
});
