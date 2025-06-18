class TumblrPost < ActiveRecord::Base
  establish_connection :sociallink
  serialize :assets
end
