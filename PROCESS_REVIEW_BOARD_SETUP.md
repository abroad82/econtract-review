# Review Board Setup Process (Repeat for future boards)

When the real e-contract site moves over from Beta, we'll create a second review board using this exact process.

## Overview
A review board is a **separate GitHub repo + Cloudflare Pages project** that captures the live site's pages each morning, stores them, and provides a collaborative workspace for the team to review, comment, and track repairs.

**Key pattern:** board ≠ site code. The e-contract landing board lives at `econtract-review` (separate from the `e-contract` site branch).

---

## Step 1: Clone the board foundation

Source: `C:\Users\Admin\Projects\contco-review` (or an existing board)

```bash
cp -r contco-review new-board-review
cd new-board-review
```

Remove contco-specific captures (keep only core UI files):
- Keep: `workbench.html`, `job-board.html`, `page-list.html`, `flow-chart.html`, `index.html`, `_worker.js`, `pages.js`
- Delete: old captured pages, old data files

---

## Step 2: Adapt pages.js manifest

Update the top of `pages-live/pages.js`:
```javascript
var L = "https://new-site.com.au/";  // change this
window.WB_PAGES = [
  {g:"1 · Entry", n:"Home", f:"N01_home.html", live:L},
  {g:"1 · Entry", n:"Register", f:"N02_register.html", live:L+"register"},
  // ... add all pages
];
```

**Pattern for naming captured files:** `<PREFIX><number>_<description>.html`
- e.g. `EC01_home.html` for e-contract, `CC01_home.html` for contco-future, etc.

---

## Step 3: Wire Supabase (team sync)

Create a **new Supabase project** (same org as contco):
1. Organization → New project
2. Run `SUPABASE-SETUP.sql` (in the project root)
3. Note the **Project URL** and **anon public key**
4. Replace placeholders in board HTML files:
   - Search: `__SUPABASE_URL__` → replace with `https://xyz.supabase.co`
   - Search: `__SUPABASE_ANON_KEY__` → replace with the anon key

---

## Step 4: Update the gate (Basic Auth)

`pages-live/_worker.js` — set the board username and password:
```javascript
const TEAM_USER = "new-board";  // change this
const TEAM_PASS = "new-board-review-2026";  // change this
```

Also update the realm and proxy whitelist:
```javascript
'Basic realm="new-board review"'  // update
if (!/^https:\/\/new-site\.com\.au\//i.test(target)) { ... }  // update
```

---

## Step 5: Create GitHub repo

```bash
gh repo create abroad82/<board-name> --public --source=. --remote=origin --push
# e.g. gh repo create abroad82/econtract-review --public --source=. --remote=origin --push
```

Result: `https://github.com/abroad82/<board-name>`

---

## Step 6: Create GitHub Actions workflows

### `refresh.yml` — daily capture + commit + deploy

```yaml
on:
  schedule:
    - cron: '0 22 * * *'  # 22:00 UTC = 6:00 AWST
  workflow_dispatch: {}

jobs:
  refresh:
    # Step 1: Capture live pages from the site
    # Step 2: Inject <base href> for asset loading in iframe
    # Step 3: Commit the diff to the repo
    # Step 4: Deploy to Cloudflare Pages
```

**For logged-out-only boards (like e-contract landing):**
- No login needed → simplify capture to just fetch each URL
- No test account secrets required

**For full-site boards (like contco):**
- Use contractor + employee test logins
- Add secrets: `CONTCO_CONTRACTOR_EMAIL`, `CONTCO_CONTRACTOR_PASS`, `CONTCO_EMPLOYEE_EMAIL`, `CONTCO_EMPLOYEE_PASS`
- Capture 3 roles: loggedout, contractor (logged-in), employee (logged-in)

### `deploy.yml` — auto-deploy on push

Triggers whenever `pages-live/**` changes on `main` (when refresh.yml commits).

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'pages-live/**'
```

---

## Step 7: Add GitHub secret

```bash
echo -n "<YOUR_CLOUDFLARE_API_TOKEN>" > /tmp/token.txt
gh secret set CLOUDFLARE_API_TOKEN -R abroad82/<board-name> < /tmp/token.txt
rm /tmp/token.txt
```

⚠️ **Important:** Use a file to avoid PowerShell BOM (Byte Order Mark) being prepended to the token. Get the token from Cloudflare Dashboard → Profile → API Tokens (create a new one with "Edit Cloudflare Pages" permission).

---

## Step 8: Create Cloudflare Pages project

```bash
npx wrangler@4 pages project create <project-name> --production-branch=production
# e.g. econtract-review
```

Result: `https://<project-name>.pages.dev`

---

## Step 9: Test the workflow

```bash
gh workflow run refresh.yml -R abroad82/<board-name>
# Wait ~45 seconds, then check:
gh run list -R abroad82/<board-name> -L 1
```

✅ Should see: `completed success` (or similar)

---

## Step 10: Verify live

```bash
curl -u "board-user:board-pass" https://<board-name>.pages.dev/
# Should return 200 OK
```

---

## Post-setup: when the real site moves over from Beta

1. **Expand the manifest** (`pages.js`)
   - Add logged-in pages (contractors, employees, shared flows)
   - Update URLs if the path structure changed

2. **Add test accounts** (if capturing logged-in states)
   - Set `CONTRACTOR_EMAIL`, `CONTRACTOR_PASS` secrets, etc.
   - Update `refresh.yml` to capture contractor + employee roles

3. **Re-run workflow** to seed the board with fresh captures from production

4. **Optional:** Archive the landing-only board or keep it as a reference (side-by-side views are useful)

---

## Cloudflare account details

- **Account ID:** `14d2fb99ae902acf9ce452f2ee7671dc`
- **Existing projects:** `contco-workbench`, `econtract-review`
- **Token:** stored as GitHub secret on each repo (never local)

---

## File locations

- **econtract landing board:** `C:\Users\Admin\Projects\econtract-review\`
- **contco board (reference):** `C:\Users\Admin\Projects\contco-review\`
- **e-contract site code:** `C:\Users\Admin\_codereview\wt-econtract\` (branch `e-contract`)
