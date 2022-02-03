class TwitterTweet < ActiveRecord::Base
  serialize :entries
  serialize :original_poster
  establish_connection :development

  serialize :reply_data
  serialize :quoting_data
  serialize :retweet_data

  def referenced_ids
    tweet_ids = []
    if self[:reply_data]
      tweet_ids << self[:reply_data][:permalink].split('/')[-1]
    end
    if self[:retweet_data]
      tweet_ids << self[:retweet_data][:permalink].split('/')[-1]
    end
    if self[:quoting_data]
      tweet_ids << self[:quoting_data][:permalink].split('/')[-1]
    end
    return tweet_ids
  end

  def original
    if self[:is_retweet] && self.retweet_data
      parent_id = self.retweet_data[:permalink].split('/')[-1]
      tweet = TwitterTweet.where(tweet_id: parent_id).first
      return tweet
    end
    return nil
  end

  def reply
    if self[:is_reply] && self.reply_data
      parent_id = self.reply_data[:permalink].split('/')[-1]
      tweet = TwitterTweet.where(tweet_id: parent_id).first
      return tweet
    end
    return nil
  end

  def quoting
    if self[:is_quoting] && self.quoting_data
      parent_id = self.quoting_data[:permalink].split('/')[-1]
      tweet = TwitterTweet.where(tweet_id: parent_id).first
      return tweet
    end
    return nil
  end
end
