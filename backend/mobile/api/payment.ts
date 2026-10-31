import { api } from "./client";

export type PaymentData = {
  planType: "mensal" | "anual";
  amount: number;
  token: string;
  installments?: number;
};

export async function processPayment(data: PaymentData) {
  return api.post<{ success: boolean; message: string }>("/api/process-payment", data);
}
