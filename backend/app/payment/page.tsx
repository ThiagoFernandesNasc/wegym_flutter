"use client";

export const dynamic = 'force-dynamic';

import React, { useMemo, useEffect, useState, useCallback } from 'react';
import { ChevronLeft, ShieldCheck, Loader2, CheckCircle, XCircle } from 'lucide-react';
import { useRouter, useSearchParams } from 'next/navigation';
import nextDynamic from 'next/dynamic';
import { useTranslations } from '@/lib/i18n/hook';
import { AuthGuard } from '@/components/auth/AuthGuard';

const PLANS: Record<string, { amount: number; description: string }> = {
  mensal: { amount: 49.90, description: 'wegym-pro-mensal' },
  anual: { amount: 399.90, description: 'wegym-pro-anual' },
};

const CardPayment = nextDynamic(
  () => import('@mercadopago/sdk-react').then((mod) => mod.CardPayment),
  { 
    ssr: false,
    loading: () => <Loader2 className="w-8 h-8 text-orange-500 animate-spin mx-auto" />
  }
);

export default function PaymentPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useTranslations();
  const [isClient, setIsClient] = useState(false);
  const [mpInitialized, setMpInitialized] = useState(false);
  const [paymentStatus, setPaymentStatus] = useState<'idle' | 'processing' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const planId = searchParams.get('plan') ?? 'anual';
  const plan = PLANS[planId] ?? PLANS.anual;

  useEffect(() => {
    setIsClient(true);
    
    const initMP = async () => {
      const { initMercadoPago } = await import('@mercadopago/sdk-react');
      const publicKey = process.env.NEXT_PUBLIC_MP_PUBLIC_KEY;

      if (publicKey && publicKey.length > 0) {
        initMercadoPago(publicKey);
        setMpInitialized(true);
      }
    };

    initMP();
    router.prefetch('/pro');
  }, [router]);

  const initialization = useMemo(() => ({
    amount: plan.amount,
    payer: { email: '' }
  }), [plan.amount]);

  const customization = useMemo(() => ({
    visual: { 
      theme: 'dark' as const,
      hideStatusScreen: true,
    },
    paymentMethods: { maxInstallments: 12 }
  }), []);

  const onSubmit = useCallback(async (formData: {
    token: string;
    issuer_id: string;
    payment_method_id: string;
    transaction_amount: number;
    installments: number;
    payer: { email?: string };
  }) => {
    setPaymentStatus('processing');
    setErrorMsg('');

    try {
      const res = await fetch('/api/process-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          description: plan.description,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error ?? 'Erro ao processar pagamento');
      }

      if (data.status === 'approved') {
        setPaymentStatus('success');
        setTimeout(() => router.push('/pro'), 2000);
      } else {
        setPaymentStatus('error');
        setErrorMsg('Pagamento não aprovado. Tente novamente.');
      }
    } catch (err) {
      setPaymentStatus('error');
      setErrorMsg(err instanceof Error ? err.message : 'Erro ao processar pagamento');
    }
  }, [plan.description, router]);

  return (
    <AuthGuard>
    <div className="min-h-screen bg-zinc-950 text-white p-6 font-sans">
      <header className="flex items-center justify-between mb-10">
        <button 
          onClick={() => router.back()} 
          className="p-2 bg-white/5 rounded-full active:scale-95 transition-all cursor-pointer"
        >
          <ChevronLeft size={20} />
        </button>
        <div className="flex flex-col items-center">
          <h1 className="font-black italic uppercase tracking-tighter text-lg leading-none">{t('payment.title')}</h1>
          <span className="text-[8px] text-zinc-500 uppercase tracking-[0.3em] mt-1 font-bold">{t('payment.subtitle')}</span>
        </div>
        <ShieldCheck size={22} className="text-orange-500" />
      </header>

      <main className="max-w-md mx-auto">
        <div className="mb-6 p-6 bg-linear-to-br from-zinc-900 to-zinc-950 border border-white/5 rounded-[35px] flex items-center justify-between">
          <div>
            <p className="text-[10px] font-black text-orange-500 uppercase tracking-widest mb-1">{t('payment.selectedPlan')}</p>
            <h2 className="text-xl font-black italic uppercase leading-none">WEGYM PRO</h2>
            <p className="text-[10px] text-zinc-500 font-bold uppercase mt-1">{planId === 'anual' ? t('pro.yearly') : t('pro.monthly')}</p>
          </div>
          <div className="text-right">
            <p className="text-2xl font-black italic">R$ {plan.amount.toFixed(2).replace('.', ',')}</p>
            <p className="text-[8px] text-zinc-500 font-bold uppercase">{t('payment.singlePayment')}</p>
          </div>
        </div>

        <div className="bg-zinc-900/50 border border-white/5 p-6 rounded-[35px] shadow-2xl min-h-105 flex flex-col justify-center">
          {paymentStatus === 'success' ? (
            <div className="flex flex-col items-center gap-4 py-16 text-center">
              <CheckCircle className="w-16 h-16 text-emerald-500" />
              <p className="text-lg font-black italic uppercase text-emerald-400">{t('payment.success')}</p>
              <p className="text-xs text-zinc-500">{t('payment.redirecting')}</p>
            </div>
          ) : paymentStatus === 'error' ? (
            <div className="flex flex-col items-center gap-4 py-16 text-center">
              <XCircle className="w-16 h-16 text-red-500" />
              <p className="text-lg font-black italic uppercase text-red-400">{t('payment.error')}</p>
              <p className="text-xs text-zinc-500">{errorMsg}</p>
              <button
                onClick={() => setPaymentStatus('idle')}
                className="mt-4 px-6 py-3 bg-orange-600 rounded-xl font-black uppercase italic text-xs cursor-pointer"
              >
                {t('payment.tryAgain')}
              </button>
            </div>
          ) : paymentStatus === 'processing' ? (
            <div className="flex flex-col items-center gap-4 py-20 text-center">
              <Loader2 className="w-10 h-10 text-orange-500 animate-spin" />
              <p className="text-[10px] text-zinc-500 font-black uppercase tracking-[0.2em] italic">
                {t('payment.processing')}
              </p>
            </div>
          ) : isClient && mpInitialized ? (
            <CardPayment
              initialization={initialization}
              customization={customization}
              onSubmit={onSubmit}
            />
          ) : (
            <div className="flex flex-col items-center gap-4 py-20 text-center">
              <Loader2 className="w-10 h-10 text-orange-500 animate-spin" />
              <div>
                <p className="text-[10px] text-zinc-500 font-black uppercase tracking-[0.2em] italic">
                  {t('payment.configuring')}
                </p>
                <p className="text-[8px] text-zinc-700 font-bold uppercase mt-1">{t('payment.encrypted')}</p>
              </div>
            </div>
          )}
        </div>
        
        <div className="mt-8 flex flex-col items-center gap-2">
          <p className="text-[10px] text-zinc-600 font-black uppercase tracking-widest opacity-50">
            {t('payment.poweredBy')}
          </p>
          <div className="flex gap-2 opacity-20 grayscale">
            <div className="w-8 h-5 bg-zinc-800 rounded-sm" />
            <div className="w-8 h-5 bg-zinc-800 rounded-sm" />
            <div className="w-8 h-5 bg-zinc-800 rounded-sm" />
          </div>
        </div>
      </main>
    </div>
    </AuthGuard>
  );
}