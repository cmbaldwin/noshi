class Noshi
  include ActiveModel::Model

  attr_accessor :ntype, :omotegaki, :names, :paper_size,
                :font_size, :omotegaki_size,
                :omotegaki_margin_top, :names_margin_top, :names_margin_bottom
end
