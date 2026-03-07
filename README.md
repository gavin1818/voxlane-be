# Voxlane Backend

Rails API backend for Voxlane website billing and desktop-app entitlements.

ssh root@146.190.241.57

## Stack

- Ruby `3.3.10` via `rbenv`
- Rails `7.2`
- PostgreSQL
- Supabase Auth token verification
- Stripe Checkout, Customer Portal, and webhook syncing

## What This Backend Does

- Authenticates users from Supabase bearer tokens
- Proxies email OTP auth for desktop clients
- Creates or updates local `users`
- Serves website pages for login, pricing, account, release notes, and Sparkle appcast
- Creates Stripe Checkout sessions for subscriptions
- Creates Stripe Customer Portal sessions for self-service billing
- Processes Stripe webhooks and syncs subscriptions
- Reconciles a single app entitlement key: `pro`
- Registers desktop app devices
- Issues a server-side account trial when no active subscription exists

## API Endpoints

- `GET /up`
- `GET /`
- `GET /pricing`
- `GET /account`
- `GET /login`
- `POST /login/otp`
- `POST /login/verify`
- `DELETE /logout`
- `POST /checkout`
- `POST /billing/portal`
- `GET /appcast.xml`
- `GET /releases/latest`
- `POST /api/v1/auth/otp`
- `POST /api/v1/auth/verify`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/me`
- `GET /api/v1/app/entitlement`
- `POST /api/v1/app/devices`
- `POST /api/v1/billing/checkout_sessions`
- `POST /api/v1/billing/portal_sessions`
- `POST /api/v1/webhooks/stripe`

## Required Environment Variables

Copy `.env.example` to `.env` and fill in real values.

```bash
cp .env.example .env
```

Main variables:

- `SUPABASE_URL`
- `SUPABASE_JWT_SECRET` for local/shared-secret verification, or `SUPABASE_JWKS_URL` for JWKS verification
- `SUPABASE_ANON_KEY`
- `SUPABASE_JWT_AUD`
- `SUPABASE_JWT_ISSUER`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PRO_PRICE_ID`
- `FRONTEND_URL`
- `CORS_ALLOWED_ORIGINS`
- `TRIAL_DAYS`
- `ENTITLEMENT_KEY`
- `APP_DOWNLOAD_URL`
- `STRIPE_PRICE_LABEL`
- `SPARKLE_DOWNLOAD_URL`
- `SPARKLE_DOWNLOAD_LENGTH`
- `SPARKLE_EDDSA_SIGNATURE`
- `SPARKLE_LATEST_VERSION`
- `SPARKLE_LATEST_BUILD`
- `SPARKLE_MINIMUM_SYSTEM_VERSION`
- `SPARKLE_RELEASE_NOTES_URL`
- `SPARKLE_RELEASE_NOTES_ITEMS`
- `SPARKLE_PUBLISHED_AT`

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

## Stripe Webhooks

Forward Stripe events locally:

```bash
stripe listen --forward-to http://localhost:3000/api/v1/webhooks/stripe
```

Use the signing secret printed by Stripe CLI as `STRIPE_WEBHOOK_SECRET`.

Relevant events handled:

- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`

## Desktop-App Flow

1. The app signs in through Supabase.
2. The app uses backend auth proxy endpoints for OTP send/verify/refresh.
3. The app sends the Supabase access token as `Authorization: Bearer <token>`.
4. `GET /api/v1/me` or `GET /api/v1/app/entitlement` returns the current entitlement.
5. `POST /api/v1/app/devices` registers the device identifier and app version.

## Website Billing Flow

1. User signs in on `/login` using Supabase email OTP.
2. Rails stores Supabase access and refresh tokens in a cookie-backed session.
3. `/pricing` and `/account` render the current entitlement status directly from the backend.
4. Website posts to `/checkout` or `/billing/portal`.
5. Backend creates or reuses the Stripe customer for the authenticated user and redirects to Stripe.
6. Stripe webhook updates `subscriptions` and `entitlements`.
7. The macOS app and website both see the same entitlement on the next refresh.

## Sparkle Release Flow

1. Build, sign, notarize, and upload the direct macOS release zip.
2. Generate an EdDSA signature for the archive.
3. Set `SPARKLE_*` environment variables in the backend.
4. `GET /appcast.xml` serves the signed appcast entry Sparkle consumes.
5. `GET /releases/latest` serves release notes linked from the appcast.

## Data Model

- `users`
- `billing_customers`
- `subscriptions`
- `entitlements`
- `devices`
- `webhook_events`

## Notes

- This backend keeps the source of truth for entitlement state on the server.
- Trial access is account-based, not device-based.
- Current implementation assumes one main entitlement key, defaulting to `pro`.
