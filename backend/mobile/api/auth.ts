import { api, setToken, removeToken } from "./client";

type LoginResponse = {
  token: string;
  user: {
    id: string;
    email: string;
    role: "atleta" | "personal";
    name: string;
  };
};

export async function login(email: string, password: string) {
  const res = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const error = (await res.json().catch(() => null)) as { error?: string } | null;
    throw new Error(error?.error ?? "Email ou senha inválidos");
  }

  const data = (await res.json()) as LoginResponse;
  await setToken(data.token);
  return data.user;
}

export async function register(data: {
  email: string;
  password: string;
  userType: "atleta" | "personal";
  name: string;
  cpf?: string;
  cep?: string;
  city?: string;
  state?: string;
  age?: number;
  sex?: string;
  height?: number;
  weight?: number;
  experienceLevel?: string;
  cref?: string;
}) {
  await api.post("/api/auth/register", data);
}

export async function forgotPassword(email: string) {
  await api.post("/api/auth/forgot-password", { email });
}

export async function logout() {
  await removeToken();
}

export async function getProfile() {
  return api.get<{
    id: string;
    email: string;
    role: "atleta" | "personal";
    name: string;
    athlete?: {
      name: string;
      weightKg: number;
      heightCm: number;
      experienceLevel: string;
      city: string;
      state: string;
    };
    personal?: {
      name: string;
      cref: string;
    };
  }>("/api/user/profile");
}
