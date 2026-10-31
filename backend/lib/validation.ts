import { z } from 'zod';

export const emailSchema = z.string().email('Email inválido').transform(v => v.toLowerCase().trim());

export const passwordSchema = z.string().min(8, 'Senha deve ter no mínimo 8 caracteres');

export const cpfSchema = z.string().transform(v => v.replace(/\D/g, '')).pipe(
  z.string().length(11, 'CPF deve ter 11 dígitos'),
);

export const cepSchema = z.string().min(8, 'CEP inválido').max(9);

export const nameSchema = z.string().min(2, 'Nome deve ter no mínimo 2 caracteres').max(255).transform(v => v.trim());

export const ufSchema = z.string().length(2, 'UF deve ter 2 caracteres').toUpperCase();

export const forgotPasswordSchema = z.object({
  email: emailSchema,
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Token obrigatório'),
  password: passwordSchema,
});

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  userType: z.enum(['atleta', 'personal'], { message: 'Tipo de usuário inválido' }),
  name: nameSchema,
  cpf: cpfSchema.optional(),
  cep: cepSchema.optional(),
  city: z.string().max(100).optional(),
  state: ufSchema.optional(),
  age: z.coerce.number().int().min(12, 'Idade mínima: 12 anos').max(120).optional(),
  sex: z.enum(['masculino', 'feminino', 'outro']).optional(),
  height: z.coerce.number().min(50).max(250).optional(),
  weight: z.coerce.number().min(20).max(400).optional(),
  experienceLevel: z.enum(['iniciante', 'intermediario', 'avancado']).optional(),
  injury: z.string().nullable().optional(),
  healthIssues: z.string().nullable().optional(),
  medications: z.string().nullable().optional(),
  cref: z.string().optional(),
  termsAccepted: z.literal(true, { message: 'Você precisa aceitar os Termos de Uso' }),
  privacyAccepted: z.literal(true, { message: 'Você precisa aceitar a Política de Privacidade' }),
});

export const athleteRegisterSchema = z.object({
  email: emailSchema,
  name: nameSchema,
  cpf: cpfSchema,
  birthDate: z.string().optional(),
  sex: z.enum(['masculino', 'feminino', 'outro']),
  heightCm: z.coerce.number().min(50).max(250),
  weightKg: z.coerce.number().min(20).max(400),
  experienceLevel: z.enum(['iniciante', 'intermediario', 'avancado']),
  cep: z.string().min(8).max(9),
  city: z.string().max(100),
  state: ufSchema,
  phone: z.string().optional(),
  emergencyContact: z.string().optional(),
  objective: z.string().optional(),
  observations: z.string().optional(),
  availableDays: z.string().optional(),
});

export const profileUpdateSchema = z.object({
  name: nameSchema.optional(),
  weightKg: z.coerce.number().min(20).max(400).optional(),
  heightCm: z.coerce.number().int().min(50).max(250).optional(),
});

export const paymentSchema = z.object({
  transaction_amount: z.number().positive('Valor deve ser positivo'),
  token: z.string().min(1, 'Token de pagamento obrigatório'),
  installments: z.number().int().min(1).max(12),
  payment_method_id: z.string().min(1),
  issuer_id: z.number().int().positive().optional(),
  description: z.string().optional(),
  payer: z.object({
    email: z.string().email('Email do pagador inválido'),
  }),
});

export const chatSchema = z.object({
  message: z.string().min(1, 'Mensagem vazia').max(2000, 'Mensagem muito longa'),
  level: z.enum(['Iniciante', 'Intermediário', 'Avançado']).optional(),
});

export const measurementSchema = z.object({
  date: z.string().optional(),
  weight: z.coerce.number().min(20).max(400),
  muscleMass: z.coerce.number().min(0).max(200).optional(),
  bodyFat: z.coerce.number().min(0).max(70).optional(),
  note: z.string().max(500).optional(),
});

export const checkinSchema = z.object({
  mood: z.coerce.number().int().min(1).max(5),
  energy: z.coerce.number().int().min(1).max(5),
  sleepHours: z.coerce.number().min(0).max(24).optional(),
  note: z.string().max(500).optional(),
  trained: z.boolean().optional(),
});

export const socialPostSchema = z.object({
  text: z.string().max(2000).optional(),
  workoutId: z.string().uuid().optional(),
  imageUrl: z.string().url().optional(),
});

export const socialCommentSchema = z.object({
  text: z.string().min(1, 'Comentário vazio').max(1000, 'Comentário muito longo'),
});

export const friendRequestSchema = z.object({
  addresseeId: z.string().uuid().optional(),
  action: z.enum(['request', 'respond']).optional(),
  friendshipId: z.string().uuid().optional(),
});

export const messageSchema = z.object({
  receiverId: z.string().uuid(),
  text: z.string().min(1, 'Mensagem vazia').max(2000, 'Mensagem muito longa'),
});

export const challengeJoinSchema = z.object({
  challengeId: z.string().uuid(),
});

export const dietPlanSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  dailyCalories: z.coerce.number().positive().optional(),
  proteinGoal: z.coerce.number().positive().optional(),
  carbsGoal: z.coerce.number().positive().optional(),
  fatGoal: z.coerce.number().positive().optional(),
  endDate: z.string().optional(),
});

export const foodSchema = z.object({
  name: z.string().min(1).max(200),
  brand: z.string().max(200).optional(),
  servingSize: z.coerce.number().positive(),
  servingUnit: z.string().min(1).max(50),
  calories: z.coerce.number().min(0),
  proteinG: z.coerce.number().min(0),
  carbsG: z.coerce.number().min(0),
  fatG: z.coerce.number().min(0),
  fiberG: z.coerce.number().min(0).optional(),
  sodiumMg: z.coerce.number().min(0).optional(),
  category: z.string().min(1),
});

export const mealSchema = z.object({
  date: z.string().optional(),
  type: z.enum(['breakfast', 'lunch', 'dinner', 'snack']),
  notes: z.string().max(500).optional(),
});

export const addFoodToMealSchema = z.object({
  mealId: z.string().uuid(),
  foodId: z.string().uuid(),
  amount: z.coerce.number().positive().optional(),
});

export const goalSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  category: z.string().min(1),
  metric: z.string().min(1),
  targetValue: z.coerce.number().positive(),
  endDate: z.string().optional(),
});

export const goalUpdateSchema = z.object({
  id: z.string().uuid(),
  currentValue: z.coerce.number().min(0),
});

export const programSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  category: z.string().min(1),
  level: z.string().min(1),
  durationWeeks: z.coerce.number().int().positive(),
  daysPerWeek: z.coerce.number().int().min(1).max(7),
  authorId: z.string().uuid().optional(),
});

export const appointmentBookSchema = z.object({
  slotId: z.string().uuid(),
  type: z.string().max(100).optional(),
  notes: z.string().max(500).optional(),
});

export const appointmentActionSchema = z.object({
  id: z.string().uuid(),
  action: z.enum(['cancel', 'confirm']),
});

export const appointmentSlotSchema = z.object({
  date: z.string(),
  startTime: z.string().regex(/^\d{2}:\d{2}$/),
  endTime: z.string().regex(/^\d{2}:\d{2}$/),
});

export const consentSchema = z.object({
  termsAccepted: z.boolean().optional(),
  privacyAccepted: z.boolean().optional(),
  dataConsent: z.boolean().optional(),
});

export const chatResponseSchema = z.object({
  text: z.string().min(1, 'Texto da resposta obrigatório'),
  goal: z.string().min(1, 'Objetivo obrigatório'),
  exercises: z.array(z.object({
    name: z.string().min(1),
    sets: z.number().int().positive(),
    reps: z.string().min(1),
    load: z.string().min(1),
  })).min(1, 'Pelo menos um exercício é obrigatório'),
});

export type RegisterInput = z.input<typeof registerSchema>;
export type AthleteRegisterInput = z.input<typeof athleteRegisterSchema>;
export type ProfileUpdateInput = z.input<typeof profileUpdateSchema>;
export type PaymentInput = z.input<typeof paymentSchema>;
export type ChatInput = z.input<typeof chatSchema>;
