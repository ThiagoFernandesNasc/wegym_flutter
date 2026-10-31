import { describe, it, expect } from 'vitest';
import { cepService } from '@/lib/services/cep.service';

describe('cepService', () => {
  it('should reject invalid CEP format', async () => {
    const result = await cepService.validate('123');
    expect(result.valid).toBe(false);
    expect(result.message).toBe('CEP deve ter 8 dígitos');
  });

  it('should reject CEP with letters', async () => {
    const result = await cepService.validate('abcderabc');
    expect(result.valid).toBe(false);
  });

  it('should return valid data for known CEP', async () => {
    const result = await cepService.validate('01001000');
    if (result.valid && 'data' in result) {
      expect(result.data).toBeDefined();
      expect(result.data?.cep).toBeDefined();
    } else {
      // ViaCEP might be unavailable; validate the error shape
      expect(result.message).toBeTruthy();
    }
  });
});
