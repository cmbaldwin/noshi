class SavedNoshi < ApplicationRecord
  belongs_to :user
  # Only stored for paid (image-storage) users; settings alone are enough to
  # regenerate the noshi client-side for everyone else.
  has_one_attached :rendered_image

  validates :title, presence: true, length: { maximum: 120 }

  # The generator inputs we persist. Everything here is re-applied to the form
  # client-side to reproduce the design.
  SETTING_KEYS = %w[paper_size ntype omotegaki omotegaki_size font_size names background_id].freeze

  # Coerce arbitrary client-supplied params into a known-shape settings hash so
  # we never persist unexpected keys.
  def self.sanitized_settings(raw)
    hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
    hash = hash.stringify_keys.slice(*SETTING_KEYS)
    hash["names"] = Array(hash["names"]).first(5).map { |n| n.to_s }
    hash
  end

  def average_settings_summary
    [settings["omotegaki"], Array(settings["names"]).reject(&:blank?).join("・")]
      .reject(&:blank?).join(" / ")
  end
end
