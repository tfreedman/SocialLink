class FacebookRoom < ActiveRecord::Base
  serialize :participants
end
