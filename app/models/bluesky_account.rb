class BlueskyAccount < ActiveRecord::Base
  establish_connection :sociallink
end
