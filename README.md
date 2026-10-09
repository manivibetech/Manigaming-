# MANIGAMING — All Features Starter

## Included
- Mobile-friendly red-neon gaming site
- Supabase email/password signup, login, logout, password reset
- Gamer profile
- Database-backed public leaderboard
- PUBG Mobile and Free Fire tournament listing and registration
- Admin panel to publish tournaments and add scores
- SQL schema and Row Level Security policies

## Setup
1. Replace the existing GitHub `index.html` with this `index.html`, then commit to `main`. Render should redeploy.
2. In Supabase Dashboard open SQL Editor > New query, paste all of `schema.sql`, then Run.
3. In Supabase Authentication > URL Configuration, set Site URL to `https://manigaming.onrender.com` and add it to allowed redirect URLs.
4. Sign up on the website and confirm your email if required.
5. In SQL Editor, replace `YOUR_EMAIL_HERE` in the final commented SQL statement with your signup email, uncomment the statement and run it. Log out/in again to refresh the admin role.

## Security
- The `sb_publishable_` key is intended for browser use, only with RLS.
- Never put `sb_secret_`, `service_role`, database password, or any secret in HTML/GitHub.
- A secret key was shared in chat; revoke/rotate it in Supabase if possible.
- Admin role is granted in SQL, not by a browser control.
- Starter note: add server-side capacity enforcement and abuse protection before operating large or paid tournaments.
