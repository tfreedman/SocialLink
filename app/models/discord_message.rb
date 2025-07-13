class DiscordMessage < ActiveRecord::Base
  serialize :attachments
  serialize :embeds
  serialize :stickers
  serialize :reactions
  serialize :mentions
  serialize :inline_emojis

  belongs_to :user, :foreign_key => 'author_id', :class_name => 'DiscordUser', :primary_key => 'author_id'

  establish_connection :hindsight
end
