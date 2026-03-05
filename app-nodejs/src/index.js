// ============================================================
//  index.js — Node.js Express API
//  Endpoints: /health/ready, /health/live, /api/info, /api/hello
// ============================================================

const express = require('express');
const os      = require('os');
const app     = express();

app.use(express.json());

// ── Health Probes (used by AKS + App Gateway) ────────────────
app.get('/health/ready', (req, res) => {
  res.json({
    status:  'ready',
    service: 'nodejs-api',
    time:    new Date().toISOString()
  });
});

app.get('/health/live', (req, res) => {
  res.json({ status: 'alive' });
});

// ── API Endpoints ─────────────────────────────────────────────
app.get('/api/info', (req, res) => {
  res.json({
    service:     'AKS Platform Node.js API',
    version:     process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV    || 'production',
    hostname:    os.hostname(),
    node:        process.version,
    platform:    process.platform,
    uptime:      `${Math.floor(process.uptime())}s`,
    time:        new Date().toISOString()
  });
});

app.get('/api/hello', (req, res) => {
  const name = req.query.name || 'World';
  res.json({
    message: `Hello ${name} from AKS!`,
    pod:     os.hostname()
  });
});

app.get('/api/pods', (req, res) => {
  res.json({
    pod_name:  os.hostname(),
    node_env:  process.env.NODE_ENV,
    memory_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024)
  });
});

// ── Start Server ──────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Node.js API running on port ${PORT}`);
  console.log(`Pod: ${os.hostname()}`);
});
