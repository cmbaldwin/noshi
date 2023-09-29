# Old class using ActiveRecord
# class Noshi
#   belongs_to :user, optional: true

#   has_one_attached :image do |attachable|
#     attachable.variant :thumb, resize_to_fill: [500, 500]
#   end

#   attr_accessor :names_margin_bottom # Not needed now, but keeping in case needed in the future

#   # Search reference:
#   # ## Noshis for a single name
#   # Noshi.where("'fantasy' = ANY (names)")
#   # ## Noshis for multiple names
#   # Noshi.where("names @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])
#   # ## Noshis with 3 or more names
#   # Noshi.where("array_length(names, 1) >= 3")
# end

class Noshi
  include ActiveModel::Model # for validations, if needed
  include ActiveStorage::Attached::Model if defined?(ActiveStorage) # for attachments, if Active Storage is used

  attr_accessor :user_id, :ntype, :omotegaki, :names, :image, :paper_size,
                :font_size, :omotegaki_size, :omotegaki_margin_top, :names_margin_top,
                :created_at, :updated_at

  def image_thumb
    image.variant(resize_to_fill: [500, 500]) if image.attached?
  end

  # For search functionality, you may need to implement your own logic
  # as the previous logic was relying on ActiveRecord's querying
end
