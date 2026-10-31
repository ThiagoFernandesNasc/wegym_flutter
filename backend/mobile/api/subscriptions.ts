import { api } from "./client";

export type Plan = {
  id: string;
  name: string;
  price: number;
  interval: "monthly" | "yearly";
  features: string[];
};

export type Subscription = {
  id: string;
  planId: string;
  status: "active" | "cancelled" | "expired" | "trial";
  currentPeriodEnd: string;
  plan: Plan;
};

export async function getPlans() {
  return api.get<Subscription[]>("/api/subscriptions");
}

export async function getMySubscription() {
  return api.get<Subscription | null>("/api/subscriptions/me");
}

export async function subscribe(planId: string, paymentMethodId: string) {
  return api.post<{ success: boolean }>("/api/process-payment", { planId, paymentMethodId });
}

export async function cancelSubscription() {
  return api.post<{ message: string }>("/api/subscriptions/cancel");
}
