import { memo } from 'react';
import { CheckCircle2, X, Play } from 'lucide-react';
import { Exercise } from '@/types/training';
import { useTranslations } from '@/lib/i18n/hook';
import { motion } from 'framer-motion';
import { ExerciseModal } from './ExerciseModal';

interface Props {
  ex: Exercise;
  isCompleted: boolean;
  onToggle: (id: string) => void;
  showGif?: boolean;
  onOpenGif?: (ex: Exercise) => void;
  onCloseGif?: () => void;
}

export const ExerciseItem = memo(({ ex, isCompleted, onToggle, showGif, onOpenGif, onCloseGif }: Props) => {
  const { t } = useTranslations();
  const gifUrl = ex.gifUrl;

  const handleToggle = () => {
    onToggle(ex.id);
    if (!isCompleted && gifUrl && onOpenGif) {
      onOpenGif(ex);
    }
  };

  return (
    <>
      <div className="p-5 flex items-center justify-between border-b border-white/5 transition-all">
        <div className="flex items-center space-x-4">
          <motion.button
            onClick={handleToggle}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className={`w-10 h-10 rounded-xl flex items-center justify-center border-2 transition-all cursor-pointer
              ${isCompleted ? 'bg-emerald-500 border-emerald-400' : 'bg-zinc-950 border-zinc-800 hover:border-orange-500'}`}
          >
            {isCompleted ? (
              <CheckCircle2 size={18} className="text-zinc-950" />
            ) : (
              gifUrl && (
                <motion.div
                  animate={{ rotate: [0, 10, -10, 0] }}
                  transition={{ duration: 1.5, repeat: Infinity, repeatDelay: 2 }}
                >
                  <Play size={14} className="text-zinc-500" />
                </motion.div>
              )
            )}
          </motion.button>

          <div>
            <button
              onClick={() => gifUrl && onOpenGif?.(ex)}
              className={`font-black uppercase italic text-sm text-left cursor-pointer ${isCompleted ? 'text-zinc-600 line-through' : 'text-white hover:text-orange-400'} ${gifUrl ? '' : 'cursor-default'}`}
              title={gifUrl ? t('exercise.viewDemo') : undefined}
            >
              {ex.name}
            </button>
            <p className="text-[10px] text-orange-500 font-bold">
              {ex.muscle} • {ex.sets}{t('chatbot.times')}{ex.reps}
            </p>
          </div>
        </div>

        <div className="relative">
          <input
            type="number"
            placeholder={t('exercise.weightPlaceholder')}
            className="bg-zinc-900 border border-white/10 w-16 p-2 rounded-lg text-xs font-bold text-center outline-none focus:border-orange-500 text-white"
          />
          <span className="absolute -top-3 left-0 text-[8px] text-zinc-500 uppercase">{t('exercise.weight')}</span>
        </div>
      </div>

      {showGif && gifUrl && (
        <ExerciseModal
          ex={{ name: ex.name, muscle: ex.muscle, sets: ex.sets, reps: ex.reps }}
          gifUrl={gifUrl}
          isOpen={showGif}
          onClose={onCloseGif!}
        />
      )}
    </>
  );
});

ExerciseItem.displayName = 'ExerciseItem';