class BlueskyPost < ActiveRecord::Base
  establish_connection :sociallink
  serialize :post
  serialize :reason
  serialize :reply
  serialize :author
  serialize :record
  serialize :embed

  serialize :filenames
end
