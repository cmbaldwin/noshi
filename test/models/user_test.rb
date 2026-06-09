require "test_helper"

class UserTest < ActiveSupport::TestCase
  def auth_hash(overrides = {})
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-123",
      info: { email: "taro@example.com", name: "Taro", image: "https://img/x.png" }.merge(overrides)
    )
  end

  test "from_omniauth creates a user from the identity" do
    assert_difference -> { User.count }, 1 do
      user = User.from_omniauth(auth_hash)
      assert user.persisted?
      assert_equal "taro@example.com", user.email
      assert_equal "Taro", user.name
      assert_equal "https://img/x.png", user.avatar_url
    end
  end

  test "from_omniauth is idempotent for the same identity and refreshes profile" do
    User.from_omniauth(auth_hash)
    assert_no_difference -> { User.count } do
      user = User.from_omniauth(auth_hash(name: "Taro Yamada"))
      assert_equal "Taro Yamada", user.name
    end
  end

  test "display_name falls back to email" do
    user = User.new(email: "x@y.com")
    assert_equal "x@y.com", user.display_name
  end

  test "uid is unique per provider" do
    User.from_omniauth(auth_hash)
    dup = User.new(provider: "google_oauth2", uid: "uid-123", email: "z@z.com")
    assert_not dup.valid?
  end
end
