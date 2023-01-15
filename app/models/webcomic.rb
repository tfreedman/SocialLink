class Webcomic < ActiveRecord::Base
  establish_connection :sociallink
  serialize :filename
end
