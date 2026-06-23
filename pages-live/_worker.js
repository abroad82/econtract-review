// Whole-site shared-password gate for the e-contract review board (Cloudflare Pages "advanced mode").
// This file runs server-side as the Worker for EVERY request and is NOT served as a static
// asset, so the password below is never downloadable by visitors.
//
// One shared login for the whole team. To change the password: edit TEAM_PASS, then redeploy.
const TEAM_USER = "econtract";
const TEAM_PASS = "econtract-review-2026";

export default {
  async fetch(request, env) {
    const header = request.headers.get("Authorization") || "";
    const expected = "Basic " + btoa(TEAM_USER + ":" + TEAM_PASS);

    if (header !== expected) {
      return new Response("Authentication required.", {
        status: 401,
        headers: {
          "WWW-Authenticate": 'Basic realm="e-contract review", charset="UTF-8"',
          "Content-Type": "text/plain;charset=utf-8",
          "Cache-Control": "no-store"
        }
      });
    }
    // ---- "open the live site in the board": proxy an e-contract.com.au page server-side and strip
    //      X-Frame-Options so it can be shown in an iframe.
    const u = new URL(request.url);
    if (u.pathname === "/__live") {
      const target = u.searchParams.get("u") || "";
      if (!/^https:\/\/e-contract\.com\.au\//i.test(target)) {
        return new Response("Only e-contract.com.au may be proxied.", { status: 400 });
      }
      const upstream = await fetch(target, {
        headers: { "User-Agent": request.headers.get("User-Agent") || "Mozilla/5.0", "Accept": "text/html" },
        redirect: "follow"
      });
      let html = await upstream.text();
      if (!/<base\s/i.test(html)) {
        html = html.replace(/<head([^>]*)>/i, '<head$1><base href="https://e-contract.com.au/">');
      }
      return new Response(html, {
        status: upstream.status,
        headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" }
      });
    }
    // Authenticated -> serve the static files normally.
    return env.ASSETS.fetch(request);
  }
};
