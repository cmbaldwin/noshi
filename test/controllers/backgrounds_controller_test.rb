require "test_helper"

class BackgroundsControllerTest < ActionDispatch::IntegrationTest
  def attach_image(bg)
    bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                    filename: "sample.png", content_type: "image/png")
    bg
  end

  def approved_background(owner)
    bg = owner.backgrounds.build(title: "Approved", orientation: "landscape", status: "approved")
    attach_image(bg).tap(&:save!)
  end

  test "gallery is public and lists only approved backgrounds" do
    owner = create_user
    approved = approved_background(owner)
    pending = owner.backgrounds.build(title: "Pending", orientation: "landscape", status: "pending")
    attach_image(pending).save!

    get backgrounds_path
    assert_response :success
    assert_match "Approved", @response.body
    assert_no_match "Pending", @response.body
  end

  test "upload requires login" do
    get new_background_path
    assert_redirected_to root_path
  end

  test "signed-in user can upload a pending background" do
    sign_in_as(create_user)
    assert_difference -> { Background.count }, 1 do
      post backgrounds_path, params: {
        background: {
          title: "My BG", orientation: "portrait",
          image: fixture_file_upload("sample.png", "image/png")
        }
      }
    end
    bg = Background.last
    assert_equal "pending", bg.status
    assert_redirected_to mine_backgrounds_path
  end

  test "rating creates then updates a single rating" do
    owner = create_user
    bg = approved_background(owner)
    rater = create_user
    sign_in_as(rater)

    assert_difference -> { Rating.count }, 1 do
      post rate_background_path(bg, value: 5)
    end
    assert_equal 5, bg.reload.ratings_sum

    assert_no_difference -> { Rating.count } do
      post rate_background_path(bg, value: 2)
    end
    assert_equal 2, bg.reload.ratings_sum
  end

  test "user can delete only their own background" do
    owner = create_user
    bg = approved_background(owner)
    intruder = create_user
    sign_in_as(intruder)

    # Scoped to current_user.backgrounds, so another user's record isn't found.
    delete background_path(bg)
    assert_response :not_found
    assert Background.exists?(bg.id)
  end
end
