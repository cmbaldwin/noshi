class BackgroundsController < ApplicationController
  before_action :require_login, except: :index

  # Public gallery of approved community backgrounds.
  def index
    @backgrounds = Background.approved.with_attached_image
    @backgrounds = params[:sort] == "new" ? @backgrounds.newest : @backgrounds.top_rated
    @my_ratings = current_user ? current_user.ratings.where(background: @backgrounds).pluck(:background_id, :value).to_h : {}
  end

  # The signed-in user's own uploads, including pending/rejected.
  def mine
    @backgrounds = current_user.backgrounds.with_attached_image.newest
  end

  def new
    @background = current_user.backgrounds.build
  end

  def create
    @background = current_user.backgrounds.build(background_params)
    @background.status = "pending"

    if @background.save
      redirect_to mine_backgrounds_path, notice: t("background.submitted")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    background = current_user.backgrounds.find(params[:id])
    background.destroy
    redirect_to mine_backgrounds_path, notice: t("background.deleted")
  end

  # Create or update the current user's rating for a background.
  def rate
    background = Background.approved.find(params[:id])
    rating = current_user.ratings.find_or_initialize_by(background: background)
    rating.value = params[:value]

    if rating.save
      redirect_back fallback_location: backgrounds_path, notice: t("background.rated")
    else
      redirect_back fallback_location: backgrounds_path, alert: t("background.rate_failed")
    end
  end

  private

  def background_params
    params.require(:background).permit(:title, :description, :orientation, :image)
  end
end
