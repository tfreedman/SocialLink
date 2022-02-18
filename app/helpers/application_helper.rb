module ApplicationHelper
  def extract_dominant_colors(image_path, quantity=5, threshold=0.01)
      image = MiniMagick::Image.open(image_path)

      # Get image histogram
      result = image.run_command('convert', image_path, '-format', '%c', '-colors', quantity, '-depth', 8, 'histogram:info:')
      
      # Extract colors and frequencies from result
      frequencies = result.scan(/([0-9]+)\:/).flatten.map { |m| m.to_f }
      hex_values = result.scan(/(\#[0-9ABCDEF]{6,8})/).flatten
      total_frequencies = frequencies.reduce(:+).to_f
  
      # Create frequency/color pairs [frequency, hex],
      # sort by frequency,
      # ignore fully transparent colours
      # select items over frequency threshold (1% by default),
      # extract hex values,
      # return desired quantity
      frequencies
        .map.with_index { |f, i| [f / total_frequencies, hex_values[i]] }
        .sort           { |r| r[0] }
        .reject         { |r| r[1].end_with?('FF') }
        .select         { |r| r[0] > threshold }
        .map            { |r| r[1][0..6] }
        .slice(0, quantity)
    end
end
