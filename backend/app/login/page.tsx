"use client";

export const dynamic = 'force-dynamic';

import React, { useState, useEffect, useCallback } from 'react';
import { AnimatePresence } from 'framer-motion';
import { useRouter, useSearchParams } from 'next/navigation';
import { getSession, signIn, useSession } from 'next-auth/react';
import { AnimatedBackground } from '@/components/ui/AnimatedBackground';
import { Tilt3D } from '@/components/ui/Tilt3D';
import { LeftPanel } from '@/components/ui/LeftPanel';
import { maskCEP, maskCPF } from '@/utils/masks';
import { useTranslations } from '@/lib/i18n/hook';
import { LoginForm } from '@/components/login/LoginForm';
import { RegisterForm } from '@/components/login/RegisterForm';

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, status } = useSession();
  const { t } = useTranslations();

  useEffect(() => {
    const authError = searchParams.get('error');
    if (authError) {
      const errorMap: Record<string, string> = {
        CredentialsSignin: t('errors.rateLimit'),
      };
      setError(errorMap[authError] || t('errors.connectionFailed'));
      router.replace('/login');
    }
  }, [searchParams, router, t]);

  useEffect(() => {
    if (status === "authenticated" && session?.user?.role) {
      router.replace(session.user.role === "personal" ? "/personal" : "/home");
    }
  }, [status, session, router]);

  const [isLogin, setIsLogin] = useState<boolean>(true);
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const [termsAccepted, setTermsAccepted] = useState(false);
  const [privacyAccepted, setPrivacyAccepted] = useState(false);

  const [userType, setUserType] = useState<'atleta' | 'personal'>('atleta');
  const [isVerifyingCref, setIsVerifyingCref] = useState<boolean>(false);
  const [crefVerified, setCrefVerified] = useState<boolean>(false);

  const [formData, setFormData] = useState({
    name: '', email: '', cpf: '', cep: '', city: '', state: '', password: '', confirmPassword: '',
    age: '', height: '', weight: '', sex: '', experienceLevel: '',
    injury: '', healthIssues: '', medications: '', cref: '',
  });

  useEffect(() => {
    router.prefetch('/home');
    router.prefetch('/personal');
  }, [router]);

  useEffect(() => {
    const cepDigits = formData.cep.replace(/\D/g, '');
    if (cepDigits.length === 8) {
      if (formData.city && formData.state) return;
      fetch(`https://viacep.com.br/ws/${cepDigits}/json/`)
        .then(res => res.json())
        .then(data => {
          if (!data.erro) {
            setFormData(prev => ({ ...prev, city: data.localidade, state: data.uf }));
          }
        })
        .catch(() => null);
    }
  }, [formData.cep, formData.city, formData.state]);

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    let formattedValue = value;
    if (name === 'cpf') formattedValue = maskCPF(value);
    if (name === 'cep') formattedValue = maskCEP(value);
    if (name === 'cref') formattedValue = value.toUpperCase();
    setFormData(prev => ({ ...prev, [name]: formattedValue }));
    if (error) setError(null);
  }, [error]);

  const verifyCref = useCallback(async () => {
    setIsVerifyingCref(true);
    setError(null);
    setCrefVerified(false);
    try {
      const res = await fetch("/api/cref/validate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ cref: formData.cref }),
      });
      const data = await res.json();
      if (data.valid) {
        setCrefVerified(true);
      } else {
        const msg = data.errors?.[0] || t('errors.invalidCref');
        setError(msg);
        setCrefVerified(false);
      }
    } catch {
      setError(t('errors.crefValidationFailed'));
      setCrefVerified(false);
    } finally {
      setIsVerifyingCref(false);
    }
  }, [formData.cref, t]);

  const handleAuth = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!isLogin && formData.password !== formData.confirmPassword) {
      return setError(t('errors.passwordMismatch'));
    }
    if (!isLogin && !termsAccepted) {
      return setError(t('errors.termsRequired'));
    }
    if (!isLogin && !privacyAccepted) {
      return setError(t('errors.privacyRequired'));
    }
    if (!isLogin && userType === 'personal' && !crefVerified) {
      return setError(t('errors.crefRequired'));
    }

    setIsLoading(true);
    try {
      if (isLogin) {
        const res = await signIn("credentials", {
          redirect: false,
          email: formData.email.trim(),
          password: formData.password,
        });
        if (res?.error) {
          const errorMap: Record<string, string> = {
            CredentialsSignin: t('errors.invalidCredentials'),
          };
          setError(errorMap[res.error] || t('errors.connectionFailed'));
          setIsLoading(false);
        } else {
          try {
            const session = await getSession();
            const role = (session?.user as { role?: string } | undefined)?.role;
            if (role === 'personal') {
              router.push('/personal');
              return;
            }
          } catch {
            // session refetch failed transiently
          }
          router.push('/home');
        }
      } else {
        const res = await fetch('/api/auth/register', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...formData, userType, termsAccepted, privacyAccepted })
        });
        if (!res.ok) {
          const data = await res.json();
          setError(data.error || t('errors.registrationFailed'));
          setIsLoading(false);
          return;
        }
        setIsLogin(true);
        setIsLoading(false);
        setCrefVerified(false);
        setFormData(prev => ({ ...prev, password: '', confirmPassword: '' }));
      }
    } catch {
      setError(t('errors.connectionFailed'));
      setIsLoading(false);
    }
  }, [isLogin, formData, userType, crefVerified, router, t, termsAccepted, privacyAccepted]);

  if (status === "loading") {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-t-orange-600 border-zinc-800 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-zinc-950 flex items-center justify-center p-4 sm:p-8 selection:bg-orange-500 selection:text-white relative overflow-hidden">
      <AnimatedBackground />
      <Tilt3D
        intensity={4}
        scale={1.006}
        glareOpacity={0.1}
        className="w-full max-w-6xl bg-zinc-900/50 backdrop-blur-2xl rounded-3xl shadow-2xl overflow-hidden flex flex-col md:flex-row relative z-10 border border-zinc-800 my-auto max-h-fit"
      >
        <LeftPanel />
        <div className="w-full md:w-2/3 p-8 sm:p-12 relative flex items-start justify-center max-h-[85vh] overflow-y-auto">
          <div className="relative w-full max-w-2xl">
            <AnimatePresence mode="wait">
              {isLogin ? (
                <LoginForm
                  formData={{ email: formData.email, password: formData.password }}
                  showPassword={showPassword}
                  isLoading={isLoading}
                  error={error}
                  onInputChange={handleInputChange}
                  onTogglePassword={() => setShowPassword(!showPassword)}
                  onSubmit={handleAuth}
                />
              ) : (
                <RegisterForm
                  userType={userType}
                  formData={formData}
                  isVerifyingCref={isVerifyingCref}
                  crefVerified={crefVerified}
                  termsAccepted={termsAccepted}
                  privacyAccepted={privacyAccepted}
                  isLoading={isLoading}
                  error={error}
                  onInputChange={handleInputChange}
                  onSetUserType={(type) => { setUserType(type); setError(null); }}
                  onVerifyCref={verifyCref}
                  onSetTermsAccepted={setTermsAccepted}
                  onSetPrivacyAccepted={setPrivacyAccepted}
                  onSetFormData={(updater) => setFormData(updater)}
                  onSubmit={handleAuth}
                />
              )}
            </AnimatePresence>

            <div className="mt-8 text-center">
              <button onClick={() => { setIsLogin(!isLogin); setError(null); setCrefVerified(false); }} className="text-zinc-400 text-sm font-medium hover:text-white transition-colors cursor-pointer">
                {isLogin ? t('register.noAccount') : t('register.alreadyMember')}
                <span className="text-orange-500 font-bold underline decoration-zinc-800 italic cursor-pointer">{isLogin ? t('register.createProfile') : t('login.doLogin')}</span>
              </button>
            </div>
          </div>
        </div>
      </Tilt3D>
    </div>
  );
}
