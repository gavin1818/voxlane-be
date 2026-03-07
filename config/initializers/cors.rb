Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*AppConfig.allowed_origins)

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Stripe-Signature"]
  end
end
