class SocialLinkContact < ActiveRecord::Base
  establish_connection :sociallink
  serialize :activity_cache
  serialize :default_filters
end
