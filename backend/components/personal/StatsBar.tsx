"use client";

import { CalendarDays, Target, TrendingUp, Users } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { StatCard } from "@/components/ui/DashboardElements";

interface StatsBarProps {
  activeStudents: number;
  classesPerWeek: number;
  studentsCount: number;
}

export function StatsBar({ activeStudents, classesPerWeek, studentsCount }: StatsBarProps) {
  const { t } = useTranslations();
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <StatCard title={t('personal.activeStudents')} value={String(activeStudents || studentsCount)} icon={Users} />
      <StatCard title={t('personal.classesPerWeek')} value={String(classesPerWeek)} icon={CalendarDays} />
      <StatCard title={t('personal.monthlyRevenue')} value="R$ —" icon={TrendingUp} />
      <StatCard title={t('personal.retentionRate')} value="—" icon={Target} />
    </div>
  );
}
