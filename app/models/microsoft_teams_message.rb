class MicrosoftTeamsMessage < ActiveRecord::Base
  establish_connection :hindsight

  belongs_to :conversation, :foreign_key => 'conversation_id', :class_name => 'MicrosoftTeamsConversation', :primary_key => 'conversation_id'

  serialize :properties
  serialize :ams_references
end
