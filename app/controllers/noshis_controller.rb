class NoshisController < ApplicationController
  def index
    @noshi = Noshi.new
    @community_backgrounds = approved_backgrounds
    # "Open in editor" from a saved noshi: settings are applied client-side.
    if user_signed_in? && params[:saved]
      @saved_noshi = current_user.saved_noshis.find_by(id: params[:saved])
      @missing_background = saved_noshi_missing_background?(@saved_noshi)
    end
  end

  def new
    @noshi = if new_noshi_params.empty?
               Noshi.new
             else
               Noshi.new(new_noshi_params)
             end
    @community_backgrounds = approved_backgrounds
  end

  def create
    head :no_content
  end

  def about; end
  def privacy; end
  def terms; end

  private

  def approved_backgrounds
    Background.approved.with_attached_image.top_rated
  end

  # A saved design can reference a community background that was later deleted
  # or unapproved. We can still restore everything else, but the background
  # itself is gone — so the view warns the user.
  def saved_noshi_missing_background?(saved)
    return false unless saved

    bg_id = saved.settings["background_id"]
    bg_id.present? && !Background.approved.exists?(id: bg_id)
  end

  def new_noshi_params
    params[:names] = params[:names].split(/[, ]+/).flatten if params[:names].present?
    params[:ntype] = params[:ntype].to_i if params[:ntype].present?
    params.slice(:ntype, :omotegaki, :names).permit!
  end
end
