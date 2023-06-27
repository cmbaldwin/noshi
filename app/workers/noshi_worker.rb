class NoshiWorker
  # include Sidekiq::Worker
  # sidekiq_options retry: 0, queue: :default

  # sidekiq_retries_exhausted do |msg, _ex|
  #   Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  # end

  # To create vertical placement
  def add_line_breaks(str)
    str.scan(/.{1}/).join("\n")
  end

  def format_name(name)
    # Replacing improper vertical characters
    [['(株)', '㈱'], ['(有)', '㈲'], ['ー', '|']]
      .each { |replacement| name.gsub!(replacement[0], replacement[1]) }
    add_line_breaks(name)
  end

  def scale_font(pt_str, adjustment)
    pt_str.to_f * adjustment
  end

  def perform(noshi_id)
    @noshi = Noshi.find(noshi_id)

    # Set up variables
    paper_size = @noshi.paper_size
    portrait = paper_size.include?('縦')
    a4 = paper_size.include?('A4')
    omotegaki = add_line_breaks(@noshi.omotegaki)
    omote_point_size = scale_font(@noshi.omotegaki_size, 1.2) # Minor scaling for difference in font apperance
    omote_top_margin = @noshi.omotegaki_margin_top
    name_point_size = scale_font(@noshi.font_size, 1.1) # Minor scaling for difference in font apperance
    names_top_margin = @noshi.names_margin_top
    name_array = @noshi.names
                       .map { |name| format_name(name) }.compact_blank
    name_count = name_array.count
    b5_long_px = 3035 # px@300dpi (JIS https://www.papersizes.org/japanese-sizes.htm in mm)
    b5_short_px = 2150
    a4_long_px = 3508
    a4_short_px = 2480
    portrait_gravitys = [0.1707, 0.5004, 0.8374] # percentage of page width to get to gravity point
    # Pull Noshi Type Image
    noshi_base = MiniMagick::Image.open("https://storage.googleapis.com/funabiki-online.appspot.com/noshi/noshi#{@noshi.ntype}.jpg")
    # Create the overlay image from blank
    overlay = MiniMagick::Image.open('https://storage.googleapis.com/funabiki-online.appspot.com/noshi/noshi_blank.png')
    # font = open(ENV["GBUCKET_PREFIX"] + "fonts/TakaoPMincho.ttf") // slower pull from GCloud, cache?
    font = Rails.root.join('app/assets/fonts/TakaoPMincho.ttf')

    # Setup the overlay image
    # Resize to A4 @ 300dpi Portrait: (short side x long side) or Landscape (long side x short side)
    landscape = a4 ? "#{a4_long_px}x#{a4_short_px}" : "#{b5_long_px}x#{b5_short_px}"
    pixel_dimensions = if portrait
                         a4 ? "#{a4_short_px}x#{a4_long_px}" : "#{b5_short_px}x#{b5_long_px}"
                       else
                         a4 ? "#{a4_long_px}x#{a4_short_px}" : "#{b5_long_px}x#{b5_short_px}"
                       end
    noshi_base.resize pixel_dimensions
    overlay.resize landscape # Always start from landscape dimensions for the overlay, then rotate if portrait
    overlay.rotate '-90' if portrait

    # Lambda to avoid repeating self for 3-up portrait styles Noshis
    print_texts = lambda do |image, gravity|
      base_offset = 0 if gravity.zero?
      base_offset ||= (overlay.width / 2) - (gravity * overlay.width)
      image.pointsize omote_point_size
      image.draw "text #{base_offset},#{omote_top_margin} '#{omotegaki}'"
      image.pointsize name_point_size
      name_count.times do |i|
        # Placement based on point size and iteration
        # Half of names area width (for center) minus index times name width
        name_width = name_point_size * 1.1 # 1.1 to account for char spacing
        x_offset = if name_count > 1
                     (((name_count + 1) * name_width) / 2) - (((i + 1) * name_width))
                   else
                     0
                   end
        image.draw "text #{base_offset + x_offset},#{names_top_margin} '#{name_array[i]}'"
      end
    end

    # Combine options provides access to ImageMagick's inline image modification string format: mogrify
    # https://www.imagemagick.org/script/mogrify.php
    overlay.combine_options do |image|
      # North center to get placement by top margin in points
      image.gravity 'North'
      image.font font
      image.fill('#000000')
      # Placement based on point size and top margin
      if portrait
        # Count number of names in array, add a name for each time
        portrait_gravitys.each do |gravity|
          print_texts.call(image, gravity)
        end
      else
        print_texts.call(image, 0)
      end
    end

    complete_noshi = noshi_base.composite(overlay) do |comp|
      # Overlay composition: https://legacy.imagemagick.org/Usage/compose/#over
      comp.compose 'Over'
      # Copy second_image onto first_image without re-positioning
      comp.geometry '+0+0'
    end

    ##
    # Duplicate and change placement three times for tall 3-up Noshi
    ##

    # Setup and save the file
    complete_noshi.format 'png'
    # Name the file
    fname = "#{@noshi.omotegaki}_#{@noshi.names.join('-')}_"
    dkey = Time.zone.now.strftime('%Y%m%d%H%M%S')
    ext = '.png'
    final_name = fname + dkey + ext
    # Write a temporary version
    complete_noshi.write final_name

    # Write/stream the file to the uploader
    @noshi.image.attach(io: File.open(final_name), filename: final_name)
    @noshi.save
    # Delete the original temporary file
    File.delete(final_name) if File.exist?(final_name)
    GC.start
  end
end
