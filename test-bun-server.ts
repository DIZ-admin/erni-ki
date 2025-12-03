// Bun HTTP Server Performance Test
const DEFAULT_PORT = 3333;
const PORT = Number.parseInt(process.env.PORT ?? `${DEFAULT_PORT}`, 10);
const port = Number.isFinite(PORT) ? PORT : DEFAULT_PORT;

try {
  const server = Bun.serve({
    port,
    fetch(req) {
      const url = new URL(req.url);

      if (url.pathname === '/') {
        return new Response('Hello from Bun!', {
          headers: { 'Content-Type': 'text/plain' },
        });
      }

      if (url.pathname === '/json') {
        return Response.json({
          message: 'Fast JSON response',
          timestamp: Date.now(),
          server: 'Bun',
        });
      }

      if (url.pathname === '/health') {
        return Response.json({ status: 'healthy' });
      }

      return new Response('Not Found', { status: 404 });
    },
    error(error) {
      console.error('Unhandled server error:', error);
      return new Response('Internal Server Error', { status: 500 });
    },
  });

  console.log(`🚀 Bun server running at http://localhost:${server.port}`);
  console.log(`📊 Test endpoints:`);
  console.log(`   - http://localhost:${server.port}/`);
  console.log(`   - http://localhost:${server.port}/json`);
  console.log(`   - http://localhost:${server.port}/health`);
  console.log(`\n⏱️  Server started in ${performance.now().toFixed(2)}ms`);
  console.log(`\n🛑 Press Ctrl+C to stop`);
} catch (error) {
  console.error(`Failed to start server on port ${port}:`, error);
  process.exit(1);
}
