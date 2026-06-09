class Background < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many :ratings, dependent: :destroy

  STATUSES = %w[pending approved rejected].freeze
  ORIENTATIONS = %w[landscape portrait].freeze
  ACCEPTED_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SIZE = 8.megabytes

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 500 }
  validates :status, inclusion: { in: STATUSES }
  validates :orientation, inclusion: { in: ORIENTATIONS }
  validate :acceptable_image

  scope :approved, -> { where(status: "approved") }
  scope :pending,  -> { where(status: "pending") }
  scope :newest,   -> { order(created_at: :desc) }
  # Highest rated first, then most-rated, then newest.
  scope :top_rated, lambda {
    # SQLite sorts NULLs last on DESC, so unrated rows fall to the bottom.
    order(Arel.sql("CAST(ratings_sum AS FLOAT) / NULLIF(ratings_count, 0) DESC"))
      .order(ratings_count: :desc, created_at: :desc)
  }

  def approved? = status == "approved"

  def average_rating
    return 0.0 if ratings_count.zero?

    (ratings_sum.to_f / ratings_count).round(1)
  end

  # Recompute the denormalized tallies from the rating rows.
  def recalculate_rating!
    update_columns(ratings_count: ratings.count, ratings_sum: ratings.sum(:value))
  end

  private

  def acceptable_image
    unless image.attached?
      errors.add(:image, :blank)
      return
    end

    errors.add(:image, :invalid) unless image.content_type.in?(ACCEPTED_TYPES)
    errors.add(:image, :too_big) if image.blob&.byte_size.to_i > MAX_SIZE
  end
end
