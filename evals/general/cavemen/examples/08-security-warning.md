**Security warning — please read this carefully.**

Any API key embedded in frontend JavaScript is fully visible to every user of your application. Browser DevTools, View Source, and network inspection all expose it in plain text. Anyone who finds the key can use it to make requests on your behalf, potentially incurring charges or accessing protected data. This cannot be mitigated by obfuscation, minification, or environment variables at build time — the key will always end up in the client bundle.

Do not store secret API keys in frontend code.

---

What to do instead:

**Backend proxy** — safest path. Frontend calls your server, server calls API with key stored in env. Key never leaves server.

```
Browser → POST /api/data → Your Server (has API_KEY) → External API
```

**Restricted keys** — some APIs (Google Maps, Stripe publishable) offer browser-safe keys with domain restrictions + limited scope. These are OK in frontend because they're designed for it. Check if your API supports this.

**Serverless fn** — if no backend exists, one Vercel/Netlify/Lambda fn acts as proxy. Minimal setup, same protection.

```js
// api/proxy.js (serverless function)
export default async function handler(req, res) {
  const response = await fetch('https://api.example.com/data', {
    headers: { Authorization: `Bearer ${process.env.API_KEY}` },
  });
  const data = await response.json();
  res.json(data);
}
```

Frontend calls `/api/proxy` → fn adds key server-side → forwards to real API. Key stays in env, never shipped to browser.

Pick backend proxy or serverless fn. Both solve problem with ~20 lines of code.
