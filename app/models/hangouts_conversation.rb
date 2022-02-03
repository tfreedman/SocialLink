class HangoutsConversation < ActiveRecord::Base
  establish_connection :hindsight
  serialize :conversation_type
  serialize :self_conversation_state
  serialize :read_state
  serialize :otr_status
  serialize :otr_toggle
  serialize :current_participant
  serialize :participant_data
  serialize :network_type
  serialize :force_history_state
  serialize :group_link_sharing_status
end
