class MastodonToot < ActiveRecord::Base
  establish_connection :sociallink
  serialize :account
  serialize :media_attachments
  serialize :reblog
  serialize :application
  serialize :card

  serialize :mentions
  serialize :tags
  serialize :emojis
end
