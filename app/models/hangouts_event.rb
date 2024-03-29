class HangoutsEvent < ActiveRecord::Base
  establish_connection :hindsight
  serialize :sender_id
  serialize :self_event_state
  serialize :chat_message
  serialize :advances_sort_timestamp
  serialize :delivery_medium
end
