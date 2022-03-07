class PixivPost < ActiveRecord::Base
  establish_connection :sociallink
  serialize :filenames
end
