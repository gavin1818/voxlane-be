## **Create a new app via Dokku**

With that out of the way, we’ve successfully installed and configured Dokku on a remote machine via Digital Ocean. Next, we can create the app in the remote environment to match the one we set up earlier.

```bash
# on the Dokku host via Digital Ocean SSH
dokku apps:create voxlane-be

```

```bash
dokku apps:create voxlane-be
-----> Creating voxlane-be...
-----> Creating new app virtual host file...

```

---

## Remove the dockerfile

just remove the dockerfile in the project

## **Databases**

Dokku doesn’t provide datastores by default so we need to install those independently.

I prefer [**PostgreSQL**](https://www.postgresql.org/) on my apps (mostly because It’s what I’ve always used).

```bash
# on the Dokku host via Digital Ocean SSH
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git

```

This should fetch a number of dependencies and install PostgreSQL. Next, we must create a service that leverages that specific data store.

```ruby
dokku postgres:create voxlanedb

```

Finally, with that service created, we need to link back to the app we made previously.

```bash
dokku postgres:link voxlanedb voxlane-be

```


This should set the environment variable called DATABASE_URL and point to the database we just created.

### **Additional Dokku plugins**

Dokku is built out of a collection of plugins, so it makes sense that there are many others to leverage in your apps. Check out the complete list here: [**https://dokku.com/docs/community/plugins/#official-plugins-beta**](https://dokku.com/docs/community/plugins/#official-plugins-beta)

## **Local app configuration**

With the remote portion semi-setup, we must configure our app locally to respond to the database changes.

I’ll run a handy command to change our database setup from SQLite to PostgreSQL locally. This amends our **`database.yml`** file and installs the **`pg`** gem.

```bash
rails db:system:change --to=postgresql
    conflict  config/database.yml
Overwrite /path/to/dokku_demo/config/database.yml? (enter "h" for help) [Ynaqdhm] y
       force  config/database.yml
        gsub  Gemfile
        gsub  Gemfile
        gsub  Dockerfile
        gsub  Dockerfile

```

Inside the **`database.yml`** file, we’ll need to change the production environment to match the name we gave the PostSQL service we made on the remote server.

```yaml
# PostgreSQL. Versions 9.3 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On macOS with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem "pg"
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # https://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: dokku_demo_development

  # The specified database role being used to connect to PostgreSQL.
  # To create additional roles in PostgreSQL see `$ createuser --help`.
  # When left blank, PostgreSQL will use the default role. This is
  # the same name as the operating system user running Rails.
  #username: dokku_demo

  # The password associated with the PostgreSQL role (username).
  #password:

  # Connect on a TCP socket. Omitted by default since the client uses a
  # domain socket that doesn't need configuration. Windows does not have
  # domain sockets, so uncomment these lines.
  #host: localhost

  # The TCP port the server listens on. Defaults to 5432.
  # If your server runs on a different port number, change accordingly.
  #port: 5432

  # Schema search path. The server defaults to $user,public
  #schema_search_path: myapp,sharedapp,public

  # Minimum log levels, in increasing order:
  #   debug5, debug4, debug3, debug2, debug1,
  #   log, notice, warning, error, fatal, and panic
  # Defaults to warning.
  #min_messages: notice

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: dokku_demo_test

# As with config/credentials.yml, you never want to store sensitive information,
# like your database password, in your source code. If your source code is
# ever seen by anyone, they now have access to your database.
#
# Instead, provide the password or a full connection URL as an environment
# variable when you boot the app. For example:
#
#   DATABASE_URL="postgres://myuser:mypass@localhost/somedatabase"
#
# If the connection URL is provided in the special DATABASE_URL environment
# variable, Rails will automatically merge its configuration values on top of
# the values provided in this file. Alternatively, you can specify a connection
# URL environment variable explicitly:
#
#   production:
#     url: <%= ENV["MY_APP_DATABASE_URL"] %>
#
# Read https://guides.rubyonrails.org/configuring.html#configuring-a-database
# for a full overview on how database connection configuration can be specified.
#
production:
  <<: *default
  database: voxlanedb
  username: voxlanedb
  password: <%= ENV["DATABASE_URL"] %>

```

I modified the **`production`** section database and password to include the new database name and username (same as the database name). The password is the database URL variable set with Dokku in the previous step.

### **Define a new git origin**

To push and deploy changes, we’ll need to leverage a new git remote origin. This lets us effectively deploy on demand, which is a huge perk and similar to Heroku if you’ve used that before.

In most cases, you would have an origin remote to have a place to version your code, and the **`dokku`** origin would be our live environment.

Let’s commit our changes locally first:

```bash
git add .
git commit -m "Update database settings"

```

Next, add the new remote to your app. My app’s name is **`voxlane-be`**.

```ruby
git remote add dokku dokku@146.190.241.57:voxlane-be

```

Then, you can push your changes live and deploy the app to the new remote.

```bash
git push dokku main

```

With any luck, you’ll see some logs appear, which gives us a good indication that the app is deploying! However, the first deployment could take some time to kick out.

## **PostgreSQL Errors**

The latest Rails version shipping with a **`Dockerfile`** presents some issues with Dokku. To resolve the problem, I renamed the file from **`Dockerfile`** to **`.Dockerfile`**.

## **Add a `Procfile` for production**

We have a **`Procfile.dev`** file but also need one in production. For this basic app, we need to run the Rails server. You might later add a queuing service like Sidekiq or some form of service. Also, note the release line. It will handle running **`rails db:migrate`** for each deployment.

Create a file in your app's' Procfile' root directory and add the following.

```ruby
web: bin/rails server
release: rails db:migrate

```

Commit your changes with git and re-deploy once more.

```ruby
git add Procfile
git commit -m "Add Procfile"
git push dokku main

```

Success!

Add connect to a domain

```markdown

### Domain Switch

To switch your Dokku app to a custom domain (example using voxlane.io):

1. **Set DNS Records**
   - Add A record: `@` → `146.190.241.57`
   - Add CNAME (optional): `www` → `voxlane.io`
   - Wait 5-15 minutes for DNS propagation

2. **Configure Dokku**
   ```bash
   # Set domain
   dokku domains:set voxlane-be voxlane.io
   
   # For both www and non-www
   dokku domains:set voxlane-be voxlane.io www.voxlane.io

   # Setup SSL
   sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
   sudo dokku letsencrypt:cron-job --add # <- To enable auto-renew
   dokku letsencrypt:set voxlane-be email gavincdc@gmail.com
   dokku letsencrypt:enable voxlane-be
   
   # Enable auto-renewal (optional)
   dokku letsencrypt:cron-job --add
   ```

3. **Verify** by visiting `https://voxlane.io`

### SSL Certificate Issues

If you encounter "Not Secure" warnings or SSL certificate errors, follow these steps:

#### 1. Check Certificate Status
```bash
# Check certificate expiry
ssh dokku@146.190.241.57 letsencrypt:list

# Should show certificate expiry date and time remaining
```

#### 2. Identify Common Issues
- **Certificate Expired**: Browser shows "Server's certificate is expired"
- **Not Secure Warning**: Certificate is invalid or missing
- **Untrusted Authority**: Certificate chain issue

#### 3. Renew Expired Certificate
```bash
# Auto-renew certificate
ssh dokku@146.190.241.57 letsencrypt:auto-renew voxlane-be

# Or manually enable/renew
ssh dokku@146.190.241.57 letsencrypt:enable voxlane-be
```

#### 4. Set Up Auto-Renewal (Prevent Future Issues)
```bash
# Add cron job for automatic renewal
ssh dokku@146.190.241.57 letsencrypt:cron-job --add

# Verify cron job exists
ssh dokku@146.190.241.57 crontab -l
```

#### 5. Verify Fix
```bash
# Check new certificate status
ssh dokku@146.190.241.57 letsencrypt:list

# Test certificate from command line
openssl s_client -connect voxlane.io:443 -servername voxlane.io < /dev/null 2>/dev/null | openssl x509 -noout -dates

# Visit https://voxlane.io in browser - should show green lock icon
```
```