require "test_helper"

class Admin::BackgroundsControllerTest < ActionDispatch::IntegrationTest
  def pending_background
    owner = create_user
    bg = owner.backgrounds.build(title: "Pending", orientation: "landscape", status: "pending")
    bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                    filename: "sample.png", content_type: "image/png")
    bg.tap(&:save!)
  end

  test "non-admin is blocked from moderation" do
    sign_in_as(create_user)
    get admin_backgrounds_path
    assert_redirected_to root_path
  end

  test "admin sees the pending queue" do
    sign_in_as(create_user(admin: true))
    pending_background
    get admin_backgrounds_path
    assert_response :success
    assert_match "Pending", @response.body
  end

  test "admin can approve a background" do
    sign_in_as(create_user(admin: true))
    bg = pending_background

    patch admin_background_path(bg, status: "approved")
    assert_equal "approved", bg.reload.status
    assert_redirected_to admin_backgrounds_path
  end

  test "admin can reject a background" do
    sign_in_as(create_user(admin: true))
    bg = pending_background

    patch admin_background_path(bg, status: "rejected")
    assert_equal "rejected", bg.reload.status
  end
end
