require "digest"

module Auth
  module TokenDigest
    module_function

    def call(token)
      Digest::SHA256.hexdigest(token.to_s)
    end
  end
end
