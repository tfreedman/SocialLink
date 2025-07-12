class GoogleChatMessage < ActiveRecord::Base
  serialize :creator
  serialize :annotations

  establish_connection :hindsight
end
