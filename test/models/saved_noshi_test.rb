require "test_helper"

class SavedNoshiTest < ActiveSupport::TestCase
  test "sanitized_settings keeps only known keys and caps names at 5" do
    raw = {
      "paper_size" => "A4", "ntype" => "3", "omotegaki" => "御祝",
      "omotegaki_size" => "120", "font_size" => "100",
      "names" => %w[a b c d e f g], "evil" => "drop tables"
    }
    settings = SavedNoshi.sanitized_settings(raw)

    assert_equal SavedNoshi::SETTING_KEYS.sort, settings.keys.sort
    assert_equal 5, settings["names"].length
    assert_not settings.key?("evil")
  end

  test "requires a title" do
    user = User.create!(provider: "google_oauth2", uid: "x", email: "x@y.com")
    saved = user.saved_noshis.build(title: "", settings: {})
    assert_not saved.valid?
  end

  test "stores settings as a hash" do
    user = User.create!(provider: "google_oauth2", uid: "y", email: "y@y.com")
    saved = user.saved_noshis.create!(title: "Gift", settings: { "omotegaki" => "御礼" })
    assert_equal "御礼", saved.reload.settings["omotegaki"]
  end
end
