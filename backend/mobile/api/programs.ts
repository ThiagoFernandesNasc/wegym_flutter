import { api } from "./client";

export type ProgramExercise = {
  id: string; name: string; sets: number; reps: string; restSec: number; order: number;
  weekNumber: number; dayNumber: number;
};
export type Program = {
  id: string; title: string; description: string; category: string;
  durationWeeks: number; daysPerWeek: number; featured: boolean;
  exercises: ProgramExercise[];
};

export async function getPrograms() { return api.get<Program[]>("/api/programs"); }
export async function getProgram(id: string) { return api.get<Program>(`/api/programs/${id}`); }
