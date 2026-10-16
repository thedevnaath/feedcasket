import { Hono } from 'hono';
import { astro } from 'astro/hono';
import { cf } from '@astrojs/cloudflare/hono';

const app = new Hono<{ Bindings: Env }>();

// Cloudflare adapter middleware for asset handling, env bindings, context, and response finalization
app.use(cf());

// Hono handles /api/* routes
const api = new Hono<{ Bindings: Env }>();

api.get('/health', (c) => {
	return c.json({
		status: 'ok',
		message: 'API is running'
	});
});

api.all('*', (c) => {
	return c.json({ error: 'Not Found' }, 404);
});

// Mount API router
app.route('/api', api);

// Astro handles all website routes
app.all('*', astro());

export default app;
