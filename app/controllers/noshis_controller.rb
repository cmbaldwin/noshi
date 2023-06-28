class NoshisController < ApplicationController
  before_action :set_noshi, only: %i[show edit update destroy]
  before_action :authenticate_user!, only: %i[edit update destroy]

  def index
    # @noshis = Noshi.where(user: current_user)
    @noshi = Noshi.new
  end

  # POST /noshis
  def create
    # respond_to do |format|
    #   format.turbo_stream do
    #     render turbo_stream: turbo_stream
    #       .update(
    #         :noshi_image,
    #         partial: 'noshis/image',
    #         locals: { noshi: noshi_params }
    #       )
    #   end
    # end
  end

  # Used to render a full image and upload to a storage service
  def create_and_save
    @noshi = Noshi.new(noshi_params.merge({ user: current_user }))
    if @noshi.save && NoshiWorker.perform_async(@noshi.id)
      redirect_to noshi_path(@noshi), notice: t('noshi_created')
    else
      respond_to do |format|
        format.html do
          render :new, noshi_params:, status: :unprocessable_entity, notice: t('noshi_fail', errors: @noshi.errors)
        end
      end
    end
  end

  def new
    puts new_noshi_params
    @noshi = if new_noshi_params.empty?
               Noshi.new
             else
               Noshi.new(new_noshi_params)
             end
    puts @noshi.attributes
  end

  # GET /noshis/1/edit
  def edit; end

  # GET /noshis/1
  def show; end

  # PATCH/PUT /noshis/1
  def update
    respond_to do |format|
      if @noshi.update(noshi_params)
        @noshi.image.purge
        create_noshi_worker
        format.html { redirect_to :index, notice: t('noshi_modified') }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy_multiple
    Noshi.destroy(params[:noshi_ids])
    redirect_to root_path, notice: t('noshis_destroyed', count: params[:noshi_ids].count)
  end

  # DELETE /noshis/1
  def destroy
    @noshi.destroy
    respond_to do |format|
      format.html { redirect_to :index, notice: t('noshi_destroyed') }
    end
  end

  # ABOUT /about
  def about; end

  private

  def set_noshi
    @noshi = Noshi.find(params[:id])
  end

  def new_noshi_params
    # Split names by comma or space
    params[:names] = params[:names].split(/[, ]+/).flatten if params[:names].present?
    # Sanitize params
    sanitized_params = params.slice(:ntype, :omotegaki, :names)
    sanitized_params.permit!
  end

  def noshi_params
    params.require(:noshi)
          .permit(
            :user_id,
            :ntype,
            :omotegaki,
            :paper_size,
            :font_size,
            :omotegaki_size,
            :omotegaki_margin_top,
            :names_margin_bottom,
            :names_margin_top,
            names: []
          )
  end
end
