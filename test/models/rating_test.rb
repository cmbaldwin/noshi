require "test_helper"

class RatingTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(provider: "google_oauth2", uid: "r1", email: "r@x.com")
    @bg = @user.backgrounds.build(title: "BG", orientation: "landscape", status: "approved")
    @bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                     filename: "sample.png", content_type: "image/png")
    @bg.save!
  end

  test "value must be 1..5" do
    assert_not Rating.new(user: @user, background: @bg, value: 0).valid?
    assert_not Rating.new(user: @user, background: @bg, value: 6).valid?
    assert Rating.new(user: @user, background: @bg, value: 5).valid?
  end

  test "one rating per user per background" do
    Rating.create!(user: @user, background: @bg, value: 3)
    dup = Rating.new(user: @user, background: @bg, value: 4)
    assert_not dup.valid?
  end

  test "saving and destroying refreshes the background tallies" do
    rating = Rating.create!(user: @user, background: @bg, value: 5)
    assert_equal 1, @bg.reload.ratings_count
    assert_equal 5, @bg.ratings_sum

    rating.destroy
    assert_equal 0, @bg.reload.ratings_count
    assert_equal 0, @bg.ratings_sum
  end
end
