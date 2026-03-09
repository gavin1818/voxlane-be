module Auth
  class TokenGenerator
    def self.call
      SecureRandom.urlsafe_base64(48)
    end
  end
end
