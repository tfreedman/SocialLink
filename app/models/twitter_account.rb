class TwitterAccount < ActiveRecord::Base
  establish_connection :sociallink
end
