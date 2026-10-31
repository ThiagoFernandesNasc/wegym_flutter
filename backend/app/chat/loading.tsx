import { Loader2 } from "lucide-react";

export default function Loading() {
  return (
    <div className="min-h-screen bg-zinc-950 flex items-center justify-center">
      <Loader2 size={24} className="animate-spin text-orange-500" />
    </div>
  );
}
