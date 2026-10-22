require "test_helper"

class SavedNoshisControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get saved_noshis_path
    assert_redirected_to root_path
  end

  test "signed-in user can save settings and see them listed" do
    user = create_user
    sign_in_as(user)

    assert_difference -> { user.saved_noshis.count }, 1 do
      post saved_noshis_path, params: {
        title: "Wedding gift",
        settings: { paper_size: "A4", ntype: "2", omotegaki: "御祝", names: %w[船曳] }
      }, as: :json
    end
    assert_response :created

    get saved_noshis_path
    assert_response :success
    assert_match "Wedding gift", @response.body
  end

  test "free user save does not attach a rendered image even if one is sent" do
    user = create_user
    sign_in_as(user)

    post saved_noshis_path, params: {
      settings: { omotegaki: "御礼" },
      rendered_image: "data:image/jpeg;base64,#{Base64.strict_encode64("fakejpeg")}"
    }, as: :json
    assert_response :created

    assert_not user.saved_noshis.last.rendered_image.attached?
  end

  test "paid user save attaches a small rendered image" do
    user = paid_user
    sign_in_as(user)

    post saved_noshis_path, params: {
      settings: { omotegaki: "御祝" },
      rendered_image: "data:image/jpeg;base64,#{Base64.strict_encode64("fakejpeg")}"
    }, as: :json
    assert_response :created

    assert user.saved_noshis.last.rendered_image.attached?
  end

  test "paid user save drops an oversized rendered image but keeps the settings" do
    user = paid_user
    sign_in_as(user)

    assert_difference -> { user.saved_noshis.count }, 1 do
      post saved_noshis_path, params: {
        settings: { omotegaki: "御祝" },
        rendered_image: "data:image/jpeg;base64,#{"A" * 8.megabytes}"
      }, as: :json
    end
    assert_response :created

    assert_not user.saved_noshis.last.rendered_image.attached?
  end

  test "user can delete their saved noshi" do
    user = create_user
    saved = user.saved_noshis.create!(title: "X", settings: {})
    sign_in_as(user)

    assert_difference -> { user.saved_noshis.count }, -1 do
      delete saved_noshi_path(saved)
    end
    assert_redirected_to saved_noshis_path
  end

  test "opening a saved noshi warns when its community background was removed" do
    user = create_user
    bg = user.backgrounds.build(title: "BG", orientation: "landscape", status: "approved")
    bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                    filename: "sample.png", content_type: "image/png")
    bg.save!
    saved = user.saved_noshis.create!(title: "Uses bg", settings: { "background_id" => bg.id.to_s })
    sign_in_as(user)

    # Still present -> no warning.
    get root_path(saved: saved.id)
    assert_no_match I18n.t("saved_noshi.missing_background"), @response.body

    # Removed -> warning shown, rest of the design still opens.
    bg.destroy
    get root_path(saved: saved.id)
    assert_match I18n.t("saved_noshi.missing_background"), @response.body
  end

  test "cannot open another user's saved noshi in the editor" do    owner = create_user
    other = create_user
    saved = owner.saved_noshis.create!(title: "Private", settings: { omotegaki: "御祝" })

    sign_in_as(other)
    get root_path(saved: saved.id)
    assert_response :success
    # Settings JSON is only injected for the owner.
    assert_no_match "saved_noshi_settings", @response.body
  end

  private

  def paid_user
    create_user.tap do |user|
      user.create_subscription!(
        status: "active",
        current_period_end: 1.day.from_now,
        stripe_subscription_id: "sub-#{SecureRandom.hex(4)}"
      )
    end
  end
end
