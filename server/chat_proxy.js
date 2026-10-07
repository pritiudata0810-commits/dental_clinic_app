/**
 * SmileCare OS — Server-side AI Chat Proxy (/api/chat)
 *
 * Keeps your AI API key secure on the backend server so it is never exposed to client browsers.
 *
 * Usage:
 *   export AI_API_KEY="sk-proj-your-api-key"
 *   export AI_MODEL="gpt-4o-mini"
 *   node server/chat_proxy.js
 */

const http = require('http');
const https = require('https');

const PORT = process.env.PORT || 3001;
const AI_API_KEY = process.env.AI_API_KEY || '';
const AI_BASE_URL = process.env.AI_BASE_URL || 'https://api.openai.com/v1';
const AI_MODEL = process.env.AI_MODEL || 'gpt-4o-mini';

const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/api/chat' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk;
    });

    req.on('end', () => {
      try {
        const clientPayload = JSON.parse(body);

        // Forward to LLM API
        const targetUrl = new URL(`${AI_BASE_URL}/chat/completions`);
        const outgoingHeaders = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AI_API_KEY || req.headers['authorization']?.replace('Bearer ', '') || ''}`
        };

        const postData = JSON.stringify({
          model: clientPayload.model || AI_MODEL,
          messages: clientPayload.messages,
          temperature: clientPayload.temperature ?? 0.3,
          max_tokens: clientPayload.max_tokens ?? 1200,
          tools: clientPayload.tools,
          tool_choice: clientPayload.tool_choice,
          stream: clientPayload.stream ?? false
        });

        const clientReq = https.request(
          targetUrl,
          {
            method: 'POST',
            headers: outgoingHeaders
          },
          upstreamRes => {
            res.writeHead(upstreamRes.statusCode, upstreamRes.headers);
            upstreamRes.pipe(res);
          }
        );

        clientReq.on('error', err => {
          res.writeHead(502, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Upstream AI provider error', details: err.message }));
        });

        clientReq.write(postData);
        clientReq.end();
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON request body', details: err.message }));
      }
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint not found. Use POST /api/chat' }));
  }
});

server.listen(PORT, () => {
  console.log(`SmileCare AI Proxy server running on http://localhost:${PORT}/api/chat`);
});
