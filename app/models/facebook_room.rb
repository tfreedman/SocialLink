class FacebookRoom < ActiveRecord::Base
  establish_connection :hindsight
  serialize :participants
end
