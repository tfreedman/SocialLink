class FacebookRoom < ActiveRecord::Base
  establish_connection :hindsight
  serialize :participants
  has_many :messages, :foreign_key => 'room_id', :class_name => "FacebookMessage", :primary_key => 'room_id'
end
