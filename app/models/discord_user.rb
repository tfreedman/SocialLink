class DiscordUser < ActiveRecord::Base
  serialize :roles
  serialize :nickname
  serialize :avatarURL
  serialize :color

  has_many :messages, :foreign_key => 'author_id', :class_name => 'DiscordMessage', :primary_key => 'author_id'

  establish_connection :hindsight
end
