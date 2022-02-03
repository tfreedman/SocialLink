class SocialLinkContact < ActiveRecord::Base
  establish_connection :development
  serialize :activity_cache
end
