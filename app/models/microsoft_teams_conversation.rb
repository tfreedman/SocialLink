class MicrosoftTeamsConversation < ActiveRecord::Base
  establish_connection :hindsight

  has_many :messages, :foreign_key => 'conversation_id', :class_name => 'MicrosoftTeamsMessage', :primary_key => 'conversation_id'

  serialize :properties
  serialize :thread_properties
end
