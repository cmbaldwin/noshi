class NoshisController < ApplicationController
  def index
    @noshi = Noshi.new
  end

  def new
    @noshi = if new_noshi_params.empty?
               Noshi.new
             else
               Noshi.new(new_noshi_params)
             end
  end

  def create
    head :no_content
  end

  def about; end

  private

  def new_noshi_params
    params[:names] = params[:names].split(/[, ]+/).flatten if params[:names].present?
    params[:ntype] = params[:ntype].to_i if params[:ntype].present?
    params.slice(:ntype, :omotegaki, :names).permit!
  end
end
