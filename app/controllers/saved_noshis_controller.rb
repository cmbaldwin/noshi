require "base64"
require "stringio"

class SavedNoshisController < ApplicationController
  before_action :require_login

  def index
    @saved_noshis = current_user.saved_noshis.with_attached_rendered_image.order(created_at: :desc)
  end

  def create
    saved = current_user.saved_noshis.build(
      title: params[:title].presence || default_title,
      settings: SavedNoshi.sanitized_settings(params[:settings] || {})
    )

    # Rendered image is a paid-tier perk; free users save settings only.
    attach_rendered_image(saved) if current_user.image_storage?

    if saved.save
      respond_to do |format|
        format.json { render json: { id: saved.id, redirect: saved_noshis_path }, status: :created }
        format.html { redirect_to saved_noshis_path, notice: t("saved_noshi.saved") }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: saved.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to saved_noshis_path, alert: saved.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    saved = current_user.saved_noshis.find(params[:id])
    saved.destroy
    redirect_to saved_noshis_path, notice: t("saved_noshi.deleted")
  end

  private

  def default_title
    "#{t('saved_noshi.untitled')} #{Time.current.strftime('%Y-%m-%d %H:%M')}"
  end

  # Decode a "data:image/jpeg;base64,..." URL produced by the client and attach
  # it. Silently no-ops on anything that isn't a base64 image data URL.
  def attach_rendered_image(saved)
    data = params[:rendered_image].to_s
    match = data.match(%r{\Adata:(image/\w+);base64,(.+)\z}m)
    return unless match

    saved.rendered_image.attach(
      io: StringIO.new(Base64.decode64(match[2])),
      filename: "noshi-#{Time.current.to_i}.jpg",
      content_type: match[1]
    )
  end
end
