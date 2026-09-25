import { Hono } from 'hono';
import { cors } from 'hono/cors';

export type Bindings = {
  DB: D1Database;
  ENVIRONMENT: string;
};

const app = new Hono<{ Bindings: Bindings }>();

// Basic middleware
app.use('*', cors());
app.use('*', async (c, next) => {
  try {
    await next();
  } catch (err) {
    console.error('Unhandled exception:', err);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred.',
      }
    }, 500);
  }
});

// Setup /api/v1 routing structure
const api = new Hono<{ Bindings: Bindings }>();

// Health/Status Endpoint
api.get('/health', (c) => {
  return c.json({
    success: true,
    status: 'ok',
    environment: c.env.ENVIRONMENT || 'development',
    timestamp: new Date().toISOString()
  });
});

app.route('/api/v1', api);

// 404 handler
app.notFound((c) => {
  return c.json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'The requested resource was not found.',
    }
  }, 404);
});

export default app;
