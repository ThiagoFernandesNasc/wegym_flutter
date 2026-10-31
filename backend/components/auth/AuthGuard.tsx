"use client";

import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { useEffect, useRef } from "react";

interface AuthGuardProps {
  children: React.ReactNode;
  allowedRoles?: string[];
}

export function AuthGuard({ children, allowedRoles }: AuthGuardProps) {
  const { data: session, status } = useSession();
  const router = useRouter();
  const rolesRef = useRef(allowedRoles);

  useEffect(() => {
    rolesRef.current = allowedRoles;
  });

  useEffect(() => {
    if (status === "unauthenticated") {
      router.replace("/login");
      return;
    }

    if (status === "authenticated" && rolesRef.current && session?.user?.role) {
      if (!rolesRef.current.includes(session.user.role)) {
        router.replace(
          session.user.role === "personal" ? "/personal" : "/home"
        );
      }
    }
  }, [status, session, router]);

  if (status === "loading") {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-t-orange-600 border-zinc-800 rounded-full animate-spin" />
      </div>
    );
  }

  if (status === "unauthenticated") {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-t-orange-600 border-zinc-800 rounded-full animate-spin" />
      </div>
    );
  }

  if (allowedRoles && session?.user?.role && !allowedRoles.includes(session.user.role)) {
    return (
      <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-t-orange-600 border-zinc-800 rounded-full animate-spin" />
      </div>
    );
  }

  return <>{children}</>;
}
