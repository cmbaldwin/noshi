module Admin
  class BackgroundsController < ApplicationController
    before_action :require_admin

    def index
      @backgrounds = Background.pending.with_attached_image.newest
    end

    # Approve or reject a pending upload.
    def update
      background = Background.find(params[:id])
      new_status = params[:status]
      if Background::STATUSES.include?(new_status)
        background.update!(status: new_status)
        redirect_to admin_backgrounds_path, notice: t("background.moderated", status: new_status)
      else
        redirect_to admin_backgrounds_path, alert: t("background.rate_failed")
      end
    end
  end
end
