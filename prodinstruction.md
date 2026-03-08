**先澄清**

- 你说的 `project.pbxproj` line 301 实际是 `SPARKLE_APPCAST_URL`；真正的公钥占位值在 [project.pbxproj:302](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L302) 和 [project.pbxproj:360](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L360)。
- `/appcast.xml` 不是“每次不更新就一定 503”。它只有在 Sparkle 没 ready 时才 503，见 [appcasts_controller.rb:5](/Users/gavinm1/workspace/voxlane/app/controllers/web/appcasts_controller.rb#L5) 和 [app_config.rb:99](/Users/gavinm1/workspace/voxlane/app/services/app_config.rb#L99)。当前 ready 条件只有两个：`SPARKLE_DOWNLOAD_URL` 和 `SPARKLE_EDDSA_SIGNATURE`。值旧了会继续返回 200，但会发旧包。

**步骤**

1. 先把后端生产环境变量按 [.env.example:1](/Users/gavinm1/workspace/voxlane/.env.example#L1) 填到 Dokku。
   
   生产上建议 Supabase 走 `JWKS`，不要同时留着 `SUPABASE_JWT_SECRET`，因为只要它存在，后端就会改走 HS256 分支，见 [supabase_token_verifier.rb:18](/Users/gavinm1/workspace/voxlane/app/services/auth/supabase_token_verifier.rb#L18)。

   ```bash
   ssh root@146.190.241.57

   dokku config:unset --no-restart voxlane-be SUPABASE_JWT_SECRET

   dokku config:set --no-restart voxlane-be \
     SUPABASE_URL='https://<project-ref>.supabase.co' \
     SUPABASE_ANON_KEY='<supabase-anon-key>' \
     SUPABASE_JWKS_URL='https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json' \
     SUPABASE_JWT_AUD='authenticated' \
     SUPABASE_JWT_ISSUER='https://<project-ref>.supabase.co/auth/v1' \
     STRIPE_SECRET_KEY='sk_live_...' \
     STRIPE_PRO_PRICE_ID='price_...' \
     FRONTEND_URL='https://voxlane.io' \
     CORS_ALLOWED_ORIGINS='https://voxlane.io' \
     AUTH_EMAIL_REDIRECT_URL='https://voxlane.io/login' \
     STRIPE_CHECKOUT_SUCCESS_URL='https://voxlane.io/account?checkout=success' \
     STRIPE_CHECKOUT_CANCEL_URL='https://voxlane.io/pricing?checkout=cancelled' \
     STRIPE_PORTAL_RETURN_URL='https://voxlane.io/account' \
     STRIPE_PRICE_LABEL='Voxlane Pro' \
     APP_NAME='Voxlane' \
     SUPPORT_EMAIL='support@voxlane.io' \
     APP_DOWNLOAD_URL='https://voxlane.io/download' \
     SPARKLE_APPCAST_URL='https://voxlane.io/appcast.xml' \
     TRIAL_DAYS='7' \
     ENTITLEMENT_KEY='pro'

   dokku ps:restart voxlane-be
   ```

   Supabase Dashboard 里还要同步改这几项，不然邮件和跳转还是会错：

   - `Authentication -> URL Configuration -> Site URL` 设成 `https://voxlane.io`
   - `Authentication -> URL Configuration -> Redirect URLs` 至少加：
     - `https://voxlane.io/login`
     - `https://voxlane.io/account`
   - `Authentication -> Email Templates` 把 passwordless/OTP 邮件正文改成使用 6 位 `Token`，不要只放 `ConfirmationURL`
   - 如果你要保持现在 app 里的“发 6 位码 -> 手动输入”流程，建议关闭 `Confirm email`

2. 在 Stripe live mode 建生产 webhook，然后把 `STRIPE_WEBHOOK_SECRET` 填进去。  
   endpoint 用 `https://voxlane.io/api/v1/webhooks/stripe`，事件按 [README.md:110](/Users/gavinm1/workspace/voxlane/README.md#L110) 到 [README.md:114](/Users/gavinm1/workspace/voxlane/README.md#L114) 这 5 个开。

   ```bash
   dokku config:set voxlane-be STRIPE_WEBHOOK_SECRET='whsec_...'
   ```

3. 生成 Sparkle key pair，只做一次；然后把公钥填进 Xcode。  
   如果下面的 `SPARKLE_SRC` 找不到，先打开一次 Voxlane 的 Xcode 工程，让 SPM 把 Sparkle 拉下来。

   ```bash
   SPARKLE_SRC="$(find ~/Library/Developer/Xcode/DerivedData -path '*SourcePackages/checkouts/Sparkle' | head -n 1)"
   ACCOUNT='voxlane'

   swift run --package-path "$SPARKLE_SRC" generate_keys --account "$ACCOUNT"
   swift run --package-path "$SPARKLE_SRC" generate_keys --account "$ACCOUNT" -x ~/secure/voxlane-sparkle-private.key
   ```

   `generate_keys` 会打印一段：
   ```xml
   <key>SUPublicEDKey</key>
   <string>BASE64_PUBLIC_KEY</string>
   ```
   你在 Xcode 里只复制 `BASE64_PUBLIC_KEY` 这串，不要把 XML 标签一起贴进去。把 `REPLACE_WITH_SPARKLE_PUBLIC_ED_KEY` 替换掉；当前 app 的 `SPARKLE_APPCAST_URL` 已经是生产地址，见 [project.pbxproj:301](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L301)。

   私钥不要进 git，不要放 Dokku env，只放 Keychain 和离线备份。

4. 每次发版时，用最终 notarized zip 生成签名，再回填 `SPARKLE_*`。  
   更稳的顺序是：`notarize -> 产出最终 zip -> 对这个最终 zip 签名 -> 上传这个完全相同的 zip -> 更新后端 env`。不要对还会变的包签名。

   `SPARKLE_LATEST_VERSION` 必须等于 Xcode 的 `MARKETING_VERSION`，`SPARKLE_LATEST_BUILD` 必须等于 `CURRENT_PROJECT_VERSION`。当前工程里是 [project.pbxproj:296](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L296) 的 `1.0` 和 [project.pbxproj:265](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L265) 的 `20`；`.env.example` 里的 `1.0.0` 只是样例。`SPARKLE_MINIMUM_SYSTEM_VERSION` 也要和 [project.pbxproj:295](/Users/gavinm1/workspace/TypelessLocal/Voxlane.xcodeproj/project.pbxproj#L295) 的 `MACOSX_DEPLOYMENT_TARGET = 14.6` 对齐。

   ```bash
   ZIP='/absolute/path/to/Voxlane-1.0-20.zip'
   URL='https://downloads.voxlane.io/Voxlane-1.0-20.zip'
   ACCOUNT='voxlane'
   SPARKLE_SRC="$(find ~/Library/Developer/Xcode/DerivedData -path '*SourcePackages/checkouts/Sparkle' | head -n 1)"

   SIG="$(swift run --package-path "$SPARKLE_SRC" sign_update --account "$ACCOUNT" -p "$ZIP")"
   LEN="$(stat -f%z "$ZIP")"
   ```

   上传 zip 后，更新后端：
   ```bash
   dokku config:set --no-restart voxlane-be \
     SPARKLE_DOWNLOAD_URL="$URL" \
     SPARKLE_DOWNLOAD_LENGTH="$LEN" \
     SPARKLE_EDDSA_SIGNATURE="$SIG" \
     SPARKLE_LATEST_VERSION='1.0' \
     SPARKLE_LATEST_BUILD='20' \
     SPARKLE_MINIMUM_SYSTEM_VERSION='14.6' \
     SPARKLE_RELEASE_NOTES_URL='https://voxlane.io/releases/latest' \
     SPARKLE_RELEASE_NOTES_ITEMS='Fix 1|Fix 2|Fix 3' \
     SPARKLE_PUBLISHED_AT='2026-03-08T03:00:00Z'

   dokku ps:restart voxlane-be
   ```

   `SPARKLE_RELEASE_NOTES_ITEMS` 必须用 `|` 分隔，后端就是这么拆的，见 [app_config.rb:86](/Users/gavinm1/workspace/voxlane/app/services/app_config.rb#L86)。这些值会直接进 appcast XML，见 [show.xml.erb:23](/Users/gavinm1/workspace/voxlane/app/views/web/appcasts/show.xml.erb#L23)、[show.xml.erb:26](/Users/gavinm1/workspace/voxlane/app/views/web/appcasts/show.xml.erb#L26)、[show.xml.erb:28](/Users/gavinm1/workspace/voxlane/app/views/web/appcasts/show.xml.erb#L28)。

5. 每次更新后都验证一次。

   ```bash
   curl -i https://voxlane.io/appcast.xml
   curl https://voxlane.io/appcast.xml
   ```

   你要确认三件事：HTTP 200、`sparkle:edSignature` 是新值、`url`/`shortVersionString`/`version` 是新包。然后再在桌面 app 里点 `Check for Updates`。

6. 清理仓库里的测试产物。  
   `log/test.log` 现在是被 Git 跟踪的，虽然 [.gitignore:15](/Users/gavinm1/workspace/voxlane/.gitignore#L15) 和 [.gitignore:16](/Users/gavinm1/workspace/voxlane/.gitignore#L16) 已经忽略 `log` / `tmp` 了。

   ```bash
   cd /Users/gavinm1/workspace/voxlane
   git rm --cached log/test.log
   rm -f log/test.log
   ```

   `tmp/ca` 我在当前 checkout 里没找到；如果它在你别的分支或同级 repo 里存在，就同样处理：
   ```bash
   git rm -r --cached tmp/ca
   rm -rf tmp/ca
   ```

如果你把真实的 Supabase/Stripe 值和这次要发的版本号给我，我可以下一条直接替你拼出一条可执行的 `dokku config:set` 命令。
