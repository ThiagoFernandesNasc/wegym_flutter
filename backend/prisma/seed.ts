import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash("123456", 10);

  // ── Achievements ──
  const achievements = [
    { key: "first_workout", title: "Primeiro Treino", description: "Complete seu primeiro treino", icon: "🎯", category: "workouts", xpReward: 10, criteria: { type: "total_workouts", value: 1 } },
    { key: "streak_7", title: "Dedicação", description: "Treine por 7 dias consecutivos", icon: "🔥", category: "workouts", xpReward: 50, criteria: { type: "streak", value: 7 } },
    { key: "streak_30", title: "Inabalável", description: "30 dias consecutivos de treino", icon: "💎", category: "workouts", xpReward: 200, criteria: { type: "streak", value: 30 } },
    { key: "distance_10", title: "10km", description: "Corra 10km no total", icon: "🏃", category: "distance", xpReward: 30, criteria: { type: "total_distance_km", value: 10 } },
    { key: "distance_100", title: "Centenário", description: "Atinga 100km de distância total", icon: "🌍", category: "distance", xpReward: 100, criteria: { type: "total_distance_km", value: 100 } },
    { key: "workouts_50", title: "Viciado", description: "50 treinos completos", icon: "💪", category: "workouts", xpReward: 150, criteria: { type: "total_workouts", value: 50 } },
    { key: "calories_5000", title: "Fornalha", description: "Queime 5.000 calorias no total", icon: "🔥", category: "workouts", xpReward: 80, criteria: { type: "total_calories", value: 5000 } },
    { key: "early_bird", title: "Madrugador", description: "Treine antes das 7h", icon: "🌅", category: "workouts", xpReward: 20, criteria: { type: "early_workout", value: 1 } },
    { key: "first_gps", title: "Explorador", description: "Complete sua primeira atividade com GPS", icon: "🗺️", category: "distance", xpReward: 15, criteria: { type: "gps_activities", value: 1 } },
    { key: "friend_5", title: "Social", description: "Tenha 5 amigos na plataforma", icon: "🤝", category: "social", xpReward: 40, criteria: { type: "friends", value: 5 } },
    { key: "checkin_7", title: "Consistente", description: "Faça check-in por 7 dias seguidos", icon: "📋", category: "workouts", xpReward: 30, criteria: { type: "checkin_streak", value: 7 } },
  ];

  for (const ach of achievements) {
    await prisma.achievement.upsert({
      where: { key: ach.key },
      update: ach,
      create: ach,
    });
  }

  // ── Programs ──
  const programs = [
    {
      title: "Couch to 5K", description: "Programa para iniciantes que querem correr 5km em 8 semanas.", category: "running", level: "iniciante", durationWeeks: 8, daysPerWeek: 3, featured: true,
      exercises: [
        { week: 1, day: 1, name: "Caminhada 5min + Trote 1min (x8)", duration: "30min", notes: "Alternar caminhada e trote" },
        { week: 1, day: 2, name: "Caminhada 5min + Trote 1min (x6)", duration: "25min" },
        { week: 1, day: 3, name: "Caminhada 5min + Trote 1min (x8)", duration: "30min" },
        { week: 4, day: 1, name: "Corrida 5min + Caminhada 3min (x3)", duration: "24min" },
        { week: 8, day: 1, name: "Corrida 5km sem parar!", duration: "30-40min", notes: "Tente completar os 5km sem caminhar" },
      ],
    },
    {
      title: "StrongLifts 5x5", description: "Programa clássico de força com 5 exercícios compostos.", category: "gym", level: "iniciante", durationWeeks: 12, daysPerWeek: 3, featured: true,
      exercises: [
        { week: 1, day: 1, name: "Agachamento", sets: "5", reps: "5" },
        { week: 1, day: 1, name: "Supino Reto", sets: "5", reps: "5" },
        { week: 1, day: 1, name: "Remada Curvada", sets: "5", reps: "5" },
        { week: 1, day: 2, name: "Agachamento", sets: "5", reps: "5" },
        { week: 1, day: 2, name: "Desenvolvimento", sets: "5", reps: "5" },
        { week: 1, day: 2, name: "Levantamento Terra", sets: "5", reps: "5" },
      ],
    },
    {
      title: "Perda de Peso 4 Semanas", description: "Treinos HIIT e cardio para queimar gordura.", category: "weight_loss", level: "intermediario", durationWeeks: 4, daysPerWeek: 5, featured: true,
      exercises: [
        { week: 1, day: 1, name: "HIIT esteira 30s sprint / 30s descanso", duration: "20min" },
        { week: 1, day: 2, name: "Circuito funcional", sets: "3", reps: "12", notes: "Polichinelo, agachamento, flexão, prancha" },
        { week: 1, day: 3, name: "Corrida moderada", duration: "30min" },
        { week: 1, day: 4, name: "HIIT bike 20s sprint / 40s descanso", duration: "20min" },
        { week: 1, day: 5, name: "Caminhada inclinada", duration: "45min" },
      ],
    },
  ];

  for (const prog of programs) {
    const created = await prisma.program.create({
      data: { title: prog.title, description: prog.description, category: prog.category, level: prog.level, durationWeeks: prog.durationWeeks, daysPerWeek: prog.daysPerWeek, featured: prog.featured },
    });
    for (const [i, ex] of prog.exercises.entries()) {
      await prisma.programExercise.create({ data: { programId: created.id, ...ex, order: i } });
    }
  }

  // ── Food Items ──
  const foods = [
    { name: "Arroz Branco Cozido", servingSize: 100, servingUnit: "g", calories: 130, proteinG: 2.7, carbsG: 28.2, fatG: 0.3, category: "grain" },
    { name: "Arroz Integral Cozido", servingSize: 100, servingUnit: "g", calories: 124, proteinG: 2.9, carbsG: 25.8, fatG: 1.0, fiberG: 2.0, category: "grain" },
    { name: "Feijão Preto Cozido", servingSize: 100, servingUnit: "g", calories: 77, proteinG: 4.5, carbsG: 14, fatG: 0.5, fiberG: 8.5, category: "grain" },
    { name: "Peito de Frango Grelhado", servingSize: 100, servingUnit: "g", calories: 165, proteinG: 31, carbsG: 0, fatG: 3.6, category: "meat" },
    { name: "Ovo Cozido", servingSize: 1, servingUnit: "unit", calories: 78, proteinG: 6.3, carbsG: 0.6, fatG: 5.3, category: "dairy" },
    { name: "Batata Doce Cozida", servingSize: 100, servingUnit: "g", calories: 86, proteinG: 1.6, carbsG: 20.1, fatG: 0.1, fiberG: 3.0, category: "grain" },
    { name: "Banana", servingSize: 1, servingUnit: "unit", calories: 105, proteinG: 1.3, carbsG: 27, fatG: 0.4, fiberG: 3.1, category: "fruit" },
    { name: "Maçã", servingSize: 1, servingUnit: "unit", calories: 95, proteinG: 0.5, carbsG: 25, fatG: 0.3, fiberG: 4.4, category: "fruit" },
    { name: "Aveia em Flocos", servingSize: 40, servingUnit: "g", calories: 154, proteinG: 5.4, carbsG: 27.4, fatG: 2.7, fiberG: 4.0, category: "grain" },
    { name: "Whey Protein Isolado", servingSize: 30, servingUnit: "g", calories: 113, proteinG: 25, carbsG: 2, fatG: 0.5, category: "dairy" },
    { name: "Leite Desnatado", servingSize: 200, servingUnit: "ml", calories: 70, proteinG: 6.8, carbsG: 9.6, fatG: 0.2, category: "dairy" },
    { name: "Pão Integral", servingSize: 1, servingUnit: "unit", calories: 120, proteinG: 4, carbsG: 21, fatG: 2, fiberG: 3, category: "grain" },
    { name: "Azeite de Oliva", servingSize: 15, servingUnit: "ml", calories: 119, proteinG: 0, carbsG: 0, fatG: 13.5, category: "fat" },
    { name: "Brócolis Cozido", servingSize: 100, servingUnit: "g", calories: 34, proteinG: 2.8, carbsG: 6.6, fatG: 0.4, fiberG: 3.3, category: "vegetable" },
    { name: "Salmão Grelhado", servingSize: 100, servingUnit: "g", calories: 208, proteinG: 20, carbsG: 0, fatG: 13, category: "meat" },
    { name: "Abacate", servingSize: 1, servingUnit: "unit", calories: 240, proteinG: 3, carbsG: 12.8, fatG: 22, fiberG: 9.2, category: "fruit" },
    { name: "Iogurte Natural", servingSize: 170, servingUnit: "g", calories: 100, proteinG: 5.5, carbsG: 7.5, fatG: 5, category: "dairy" },
    { name: "Castanha do Pará", servingSize: 10, servingUnit: "g", calories: 64, proteinG: 1.4, carbsG: 1.2, fatG: 6.5, fiberG: 0.6, category: "fat" },
  ];

  for (const food of foods) {
    await prisma.foodItem.create({ data: { ...food, isPublic: true } });
  }

  // ── Users ──
  const personal = await prisma.user.upsert({
    where: { email: "personal@wegym.com.br" },
    update: { displayName: "Carlos Personal" },
    create: {
      email: "personal@wegym.com.br",
      passwordHash,
      role: "personal",
      displayName: "Carlos Personal",
      personal: { create: { name: "Carlos Personal", cref: "CREF000001-G/SP" } },
    },
  });

  // Training plans and athlete records reference the PersonalTrainer row ID,
  // not the parent User row ID.
  const personalTrainer = await prisma.personalTrainer.findUniqueOrThrow({
    where: { userId: personal.id },
    select: { id: true },
  });

  await prisma.user.upsert({
    where: { email: "joao@wegym.com.br" },
    update: { displayName: "João Silva" },
    create: {
      email: "joao@wegym.com.br",
      passwordHash,
      role: "atleta",
      displayName: "João Silva",
      athlete: {
        create: {
          personalId: personalTrainer.id,
          name: "João Silva",
          cpf: "12345678901",
          cep: "01001000",
          city: "São Paulo",
          state: "SP",
          age: 28,
          sex: "masculino",
          heightCm: 175,
          weightKg: 78.5,
          experienceLevel: "intermediario",
          injury: "Joelho direito (lesão LCA 2022)",
        },
      },
    },
  });

  await prisma.user.upsert({
    where: { email: "maria@wegym.com.br" },
    update: { displayName: "Maria Oliveira" },
    create: {
      email: "maria@wegym.com.br",
      passwordHash,
      role: "atleta",
      displayName: "Maria Oliveira",
      athlete: {
        create: {
          personalId: personalTrainer.id,
          name: "Maria Oliveira",
          cpf: "98765432100",
          cep: "20040020",
          city: "Rio de Janeiro",
          state: "RJ",
          age: 24,
          sex: "feminino",
          heightCm: 163,
          weightKg: 62.0,
          experienceLevel: "iniciante",
        },
      },
    },
  });

  console.log("Seed executado com sucesso!");
}

main()
  .catch((e) => {
    console.error("Erro no seed:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
