# Voxlane Backend

## to access the production server and the dokku rails app server console
ssh root@146.190.241.57
dokku run voxlane-be rails console


Rails backend for the Voxlane website, first-party authentication, Stripe billing, desktop entitlement sync, and Sparkle release metadata.

## Stack

- Ruby `3.3.10`
- Rails `7.2`
- PostgreSQL
- First-party auth with email/password, password reset, Google OAuth, JWT access tokens, and refresh sessions
- Stripe Checkout, Customer Portal, and webhook syncing

## What This Backend Does

- Serves the website pages for login, signup, password reset, pricing, account, release notes, and Sparkle appcast
- Issues first-party API sessions for the macOS client
- Supports browser-based desktop login handoff for the macOS app
- Reconciles the shared `pro` entitlement across web and desktop
- Creates Stripe Checkout sessions and Customer Portal sessions
- Processes Stripe webhooks and syncs subscriptions
- Registers desktop devices and exposes account state to the app

## Main Routes

- `GET /`
- `GET /pricing`
- `GET /login`
- `POST /login`
- `GET /signup`
- `POST /signup`
- `GET /forgot-password`
- `POST /forgot-password`
- `GET /reset-password/:token`
- `PATCH /reset-password/:token`
- `GET /auth/google`
- `GET /auth/google/callback`
- `GET /desktop-login/:public_id`
- `GET /account`
- `PATCH /account/profile`
- `PATCH /account/password`
- `DELETE /logout`
- `POST /checkout`
- `POST /billing/portal`
- `GET /appcast.xml`
- `GET /releases/latest`

## API Routes

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/desktop_sessions`
- `POST /api/v1/auth/desktop_sessions/:public_id/poll`
- `GET /api/v1/me`
- `GET /api/v1/app/entitlement`
- `POST /api/v1/app/devices`
- `POST /api/v1/billing/checkout_sessions`
- `POST /api/v1/billing/portal_sessions`
- `POST /api/v1/webhooks/stripe`

## Environment

Copy `.env.example` to `.env` and fill in real values.

```bash
cp .env.example .env
```

Important variables:

- `DATABASE_URL`
- `AUTH_JWT_SECRET`
- `AUTH_TOKEN_ISSUER`
- `AUTH_TOKEN_AUDIENCE`
- `AUTH_ACCESS_TOKEN_TTL_MINUTES`
- `AUTH_REFRESH_TOKEN_TTL_DAYS`
- `PASSWORD_RESET_TOKEN_TTL_MINUTES`
- `DESKTOP_LOGIN_TTL_MINUTES`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REDIRECT_URI`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRO_PRICE_ID`
- `FRONTEND_URL`
- `CORS_ALLOWED_ORIGINS`
- `MAILER_FROM`
- `SMTP_ADDRESS`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `SMTP_DOMAIN`
- `SUPPORT_EMAIL`
- `APP_DOWNLOAD_URL`
- `SPARKLE_*`

`AUTH_REFRESH_TOKEN_TTL_DAYS` also controls how long the website login cookie stays valid, so users stay signed in across browser restarts until that TTL expires or they sign out.

## Local Setup

```bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"
rbenv local 3.3.10
bundle install
bin/rails db:create db:migrate
bin/rails test
bin/rails server
```

## Desktop Flow

1. The macOS app posts to `POST /api/v1/auth/desktop_sessions`.
2. The backend returns a browser verification URL plus a polling token.
3. The app opens the website in the browser.
4. The user signs in on the site with Google or email/password.
5. The website approves the pending desktop login request.
6. The app polls `POST /api/v1/auth/desktop_sessions/:public_id/poll` until it receives a first-party access token and refresh token.
7. The app uses that bearer token for `/api/v1/me`, `/api/v1/app/entitlement`, and `/api/v1/app/devices`.

## Billing Flow

1. The user signs in on the website.
2. The site posts to `/checkout` or `/billing/portal`.
3. Stripe redirects back to the site.
4. Stripe webhooks update `subscriptions` and `entitlements`.
5. The website and macOS app read the same entitlement state on the next refresh.

## Data Model

- `users`
- `auth_identities`
- `auth_sessions`
- `password_reset_tokens`
- `desktop_login_requests`
- `billing_customers`
- `subscriptions`
- `entitlements`
- `devices`
- `webhook_events`
