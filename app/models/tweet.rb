class Tweet < ActiveRecord::Base
  serialize :entries
  serialize :original_poster
  establish_connection :iot
end
