import { describe, it, expect } from 'vitest';
import app from '../src/index';

describe('Health Endpoint', () => {
  it('should return 200 and status ok', async () => {
    // Note: in a worker integration test we typically test against the actual request
    // and provide env variables if needed, here we are testing the hono handler directly
    // by calling `app.request`. In Cloudflare Vitest, `env` is accessible.
    const res = await app.request('/api/v1/health', {}, { ENVIRONMENT: 'test' });

    expect(res.status).toBe(200);
    const body: any = await res.json();

    expect(body.success).toBe(true);
    expect(body.status).toBe('ok');
    expect(body.environment).toBe('test');
    expect(body).toHaveProperty('timestamp');
  });

  it('should return 404 for unknown routes', async () => {
    const res = await app.request('/unknown-route');

    expect(res.status).toBe(404);
    const body: any = await res.json();

    expect(body.success).toBe(false);
    expect(body.error.code).toBe('NOT_FOUND');
  });
});
