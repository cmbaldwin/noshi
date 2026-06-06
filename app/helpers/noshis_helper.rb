module NoshisHelper
  def omotegaki_list
    NoshiCatalog::OMOTEGAKI.map { |i| "<option>#{i}</option>" }.join
  end

  def font_sizes(selected, range)
    sizes = range
    selected_text = " selected = 'selected'"
    sizes.to_a.map { |i| "<option#{selected_text if i == selected}>#{i}</option>" }.join
  end
end
