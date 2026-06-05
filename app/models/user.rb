class User < ApplicationRecord
  has_many :saved_noshis, dependent: :destroy
  has_many :backgrounds, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_one :subscription, dependent: :destroy

  validates :provider, :uid, presence: true
  validates :email, presence: true
  validates :uid, uniqueness: { scope: :provider }

  # Find or create the local account for an OmniAuth identity. Profile fields are
  # refreshed on every sign-in so name/avatar stay current.
  def self.from_omniauth(auth)
    find_or_initialize_by(provider: auth.provider, uid: auth.uid).tap do |user|
      user.email = auth.info.email
      user.name = auth.info.name.presence || auth.info.email
      user.avatar_url = auth.info.image
      user.save
    end
  end

  def display_name
    name.presence || email
  end

  # True when the user is on the paid tier that stores rendered noshi images.
  # (Refined by the billing layer; defaults to false without an active sub.)
  def image_storage?
    subscription&.active? || false
  end
end
