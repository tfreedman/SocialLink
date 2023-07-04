class MastodonAccount < ActiveRecord::Base
  establish_connection :sociallink
end
