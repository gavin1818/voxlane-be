class Device < ApplicationRecord
  belongs_to :user

  validates :device_identifier, presence: true, uniqueness: { scope: :user_id }
end
