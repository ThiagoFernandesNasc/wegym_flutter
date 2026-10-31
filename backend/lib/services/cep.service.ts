import { cache } from '@/lib/cache';

export const cepService = {
  async validate(cep: string) {
    const clean = cep.replace(/\D/g, '');
    if (clean.length !== 8) {
      return { valid: false, message: 'CEP deve ter 8 dígitos' };
    }

    return cache.getOrSet(`cep:${clean}`, async () => {
      try {
        const res = await fetch(`https://viacep.com.br/ws/${clean}/json/`, {
          signal: AbortSignal.timeout(5000),
        });
        if (!res.ok) {
          return { valid: false, message: 'CEP não encontrado' };
        }
        const data = await res.json();
        if (data.erro) {
          return { valid: false, message: 'CEP não encontrado' };
        }
        return {
          valid: true,
          data: {
            cep: data.cep,
            logradouro: data.logradouro,
            bairro: data.bairro,
            city: data.localidade,
            state: data.uf,
          },
        };
      } catch {
        return { valid: false, message: 'Erro ao consultar CEP' };
      }
    }, 86400);
  },
};
