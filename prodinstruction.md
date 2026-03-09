# Voxlane Production Notes

## 部署重点

现在的账号系统已经不再依赖 Supabase。生产环境需要的是：

- 自建 JWT / refresh session 配置
- Google OAuth 配置
- Stripe 配置
- 邮件发送配置，用于 forgot password / reset password
- Sparkle 发布配置

## 最小环境变量

```bash
AUTH_JWT_SECRET=replace_me
AUTH_TOKEN_ISSUER=voxlane-auth
AUTH_TOKEN_AUDIENCE=voxlane-api
AUTH_ACCESS_TOKEN_TTL_MINUTES=15
AUTH_REFRESH_TOKEN_TTL_DAYS=30
PASSWORD_RESET_TOKEN_TTL_MINUTES=30
DESKTOP_LOGIN_TTL_MINUTES=10

GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=https://voxlane.io/auth/google/callback

STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...
STRIPE_PRO_PRICE_ID=...

FRONTEND_URL=https://voxlane.io
CORS_ALLOWED_ORIGINS=https://voxlane.io

MAILER_FROM="Voxlane <support@voxlane.io>"
SMTP_ADDRESS=...
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...
SMTP_DOMAIN=...

SPARKLE_APPCAST_URL=https://voxlane.io/appcast.xml
SPARKLE_DOWNLOAD_URL=...
SPARKLE_DOWNLOAD_LENGTH=...
SPARKLE_EDDSA_SIGNATURE=...
SPARKLE_LATEST_VERSION=...
SPARKLE_LATEST_BUILD=...
SPARKLE_RELEASE_NOTES_URL=https://voxlane.io/releases/latest
```

## Google OAuth

- Google Cloud Console 里把回调地址设成 `https://voxlane.io/auth/google/callback`
- Website 登录页会显示 `Continue with Google`
- macOS App 点击 login 后，会先打开网站，再通过 browser handoff 完成授权

## 邮件

- forgot password / reset password 依赖 SMTP
- 如果 `SMTP_ADDRESS` 没配，密码重置邮件在生产上不会成功发出

## macOS 登录流程

1. App 调 `POST /api/v1/auth/desktop_sessions`
2. 后端返回浏览器 URL 和 polling token
3. 用户在网站完成 Google 或邮箱密码登录
4. 网站批准 desktop login request
5. App 轮询 `POST /api/v1/auth/desktop_sessions/:public_id/poll`
6. 后端回 first-party access token / refresh token

## Stripe

- Checkout 和 Portal 还是走 Stripe Hosted Pages
- Webhook 继续把 subscription 状态同步进 `subscriptions` / `entitlements`
- 网站和 App 读的是同一份 entitlement
