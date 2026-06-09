class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :background

  validates :value, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :background_id }

  after_save :refresh_background
  after_destroy :refresh_background

  private

  def refresh_background
    background.recalculate_rating!
  end
end
