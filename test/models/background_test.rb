require "test_helper"

class BackgroundTest < ActiveSupport::TestCase
  def user
    @user ||= User.create!(provider: "google_oauth2", uid: "bg#{SecureRandom.hex(3)}", email: "bg@x.com")
  end

  def build_background(attrs = {})
    bg = user.backgrounds.build({ title: "Sakura", orientation: "landscape", status: "pending" }.merge(attrs))
    bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                    filename: "sample.png", content_type: "image/png")
    bg
  end

  test "valid with an attached image" do
    assert build_background.valid?
  end

  test "invalid without an image" do
    bg = user.backgrounds.build(title: "No image", orientation: "landscape")
    assert_not bg.valid?
    assert bg.errors[:image].any?
  end

  test "rejects an unsupported image type" do
    bg = build_background
    bg.image.blob.update!(content_type: "image/gif")
    assert_not bg.valid?
  end

  test "average_rating is zero with no ratings" do
    assert_equal 0.0, build_background.tap(&:save!).average_rating
  end

  test "recalculate_rating! sums and counts ratings" do
    bg = build_background
    bg.save!
    bg.ratings.create!(user: user, value: 4)
    other = User.create!(provider: "google_oauth2", uid: "o1", email: "o@x.com")
    bg.ratings.create!(user: other, value: 2)

    bg.recalculate_rating!
    assert_equal 2, bg.ratings_count
    assert_equal 6, bg.ratings_sum
    assert_equal 3.0, bg.average_rating
  end

  test "approved scope filters by status" do
    a = build_background(status: "approved"); a.save!
    p = build_background(status: "pending"); p.save!
    assert_includes Background.approved, a
    assert_not_includes Background.approved, p
  end
end
