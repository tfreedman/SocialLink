class MastodonToot < ActiveRecord::Base
  serialize :account
  serialize :media_attachments
  serialize :reblog
  serialize :application
  serialize :card

  serialize :mentions
  serialize :tags
  serialize :emojis
end
