class Noshi < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [500, 500]
  end

  attr_accessor :names_margin_bottom # Not needed now, but keeping in case needed in the future

  # Search reference:
  # ## Noshis for a single name
  # Noshi.where("'fantasy' = ANY (names)")
  # ## Noshis for multiple names
  # Noshi.where("names @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])
  # ## Noshis with 3 or more names
  # Noshi.where("array_length(names, 1) >= 3")
end
