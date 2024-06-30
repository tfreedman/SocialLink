class AO3Work < ActiveRecord::Base
  establish_connection :sociallink
  serialize :revisions
end
