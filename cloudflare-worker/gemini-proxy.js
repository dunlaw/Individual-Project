/**
 * GDA1 Gemini API Proxy - Cloudflare Worker
 *
 * This worker proxies Gemini API requests from the web build so that the
 * API key never needs to be embedded in the game files.
 *
 * Deployment steps:
 *   1. Install Wrangler CLI:  npm install -g wrangler
 *   2. Login:                 wrangler login
 *   3. Deploy:                wrangler deploy
 *   4. Set the API key:       wrangler secret put GEMINI_API_KEY
 *   5. Copy the deployed URL (e.g. https://gda1-gemini-proxy.your-name.workers.dev)
 *   6. Add it as a GitHub secret:  GDA1_WEB_PROXY_URL = <your-worker-url>
 *
 * The game will route web requests to:
 *   POST <proxy-url>/v1beta/models/<model>:generateContent
 *
 * The proxy appends your GEMINI_API_KEY and forwards to Google's API.
 *
 * Rate limiting:
 *   Configure Cloudflare's built-in rate limiting rules on the dashboard to
 *   prevent abuse of your API key quota.
 */

const GEMINI_BASE = "https://generativelanguage.googleapis.com";

// Allowed origins - add your GitHub Pages / itch.io URLs here
const ALLOWED_ORIGINS = [
	"https://localhost",
	"https://dun4law.github.io",
	// itch.io: "https://html-classic.itch.zone",
];

function corsHeaders(origin) {
	const allowed = ALLOWED_ORIGINS.some(
		(o) => origin === o || origin.startsWith(o),
	);
	return {
		"Access-Control-Allow-Origin": allowed ? origin : ALLOWED_ORIGINS[0],
		"Access-Control-Allow-Methods": "POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
		"Access-Control-Max-Age": "86400",
	};
}

export default {
	async fetch(request, env) {
		const origin = request.headers.get("Origin") || "";

		// Handle CORS preflight
		if (request.method === "OPTIONS") {
			return new Response(null, {
				status: 204,
				headers: corsHeaders(origin),
			});
		}

		// Health check endpoint - visit GET /health to diagnose the worker
		const url = new URL(request.url);
		if (request.method === "GET" && url.pathname === "/health") {
			const apiKey = env.GEMINI_API_KEY;
			const originAllowed = ALLOWED_ORIGINS.some(
				(o) => origin === o || origin.startsWith(o),
			);
			const health = {
				status: "ok",
				api_key_configured: !!apiKey,
				request_origin: origin || "(none)",
				origin_allowed: originAllowed,
				allowed_origins: ALLOWED_ORIGINS,
				hint: !apiKey
					? "Run: wrangler secret put GEMINI_API_KEY"
					: !originAllowed && origin
					? `Add "${origin}" to ALLOWED_ORIGINS in gemini-proxy.js, then redeploy`
					: "All good",
			};
			return new Response(JSON.stringify(health, null, 2), {
				status: 200,
				headers: {
					"Content-Type": "application/json",
					...corsHeaders(origin),
				},
			});
		}

		if (request.method !== "POST") {
			return new Response("Method Not Allowed", { status: 405 });
		}

		const apiKey = env.GEMINI_API_KEY;
		if (!apiKey) {
			return new Response(
				JSON.stringify({ error: "Proxy not configured: missing GEMINI_API_KEY" }),
				{
					status: 500,
					headers: {
						"Content-Type": "application/json",
						...corsHeaders(origin),
					},
				},
			);
		}

		// Forward path: strip leading slash, proxy the Gemini path
		// e.g. /v1beta/models/gemini-3.1-flash-lite-preview:generateContent
		const geminiPath = url.pathname.replace(/^\/+/, "");

		if (!geminiPath.startsWith("v1beta/models/")) {
			return new Response(JSON.stringify({ error: "Invalid path" }), {
				status: 400,
				headers: {
					"Content-Type": "application/json",
					...corsHeaders(origin),
				},
			});
		}

		const geminiUrl = `${GEMINI_BASE}/${geminiPath}?key=${apiKey}`;

		let body;
		try {
			body = await request.text();
		} catch {
			return new Response(JSON.stringify({ error: "Failed to read request body" }), {
				status: 400,
				headers: {
					"Content-Type": "application/json",
					...corsHeaders(origin),
				},
			});
		}

		let geminiResponse;
		try {
			geminiResponse = await fetch(geminiUrl, {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body,
			});
		} catch (e) {
			return new Response(
				JSON.stringify({ error: "Failed to reach Gemini API", detail: String(e) }),
				{
					status: 502,
					headers: {
						"Content-Type": "application/json",
						...corsHeaders(origin),
					},
				},
			);
		}

		const responseBody = await geminiResponse.text();
		return new Response(responseBody, {
			status: geminiResponse.status,
			headers: {
				"Content-Type": "application/json",
				...corsHeaders(origin),
			},
		});
	},
};
