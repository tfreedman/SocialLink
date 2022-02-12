class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [:update]
  before_action :check_session_keys, except: [:update]
  before_action :supported_types

  def supported_types
    @types = ["facebook_message", "facebook_post", "facebook_photo", "facebook_photo_of",
    "facebook_album", "hangouts_event", "instagram_post", "instagram_story",
    "tumblr_post-content--photo", "tumblr_post-content--video", "tumblr_post-content--audio",
    "tumblr_post-content--text", "tumblr_post-content--answer", "tumblr_post-content--iframe",
    "tumblr_post-content--chat", "tumblr_post-content--link", "tumblr_post-content--quote",
    "pixiv_post", "matrix_event", "android_sms", "windows_phone_sms", "reddit_comment",
    "mamirc_event", "colloquy_message", "pidgin_message", "twitter_tweet", "twitter_retweet",
    "deviantart_post", "webcomics_strip", "youtube_video"]
  end


  # TODO: add a real authentication solution
  def check_session_keys
    if !session[:key] || (session[:key] && session[:key] != "hello!")
      render :json => {:status=>false}, :status => 401 and return
#    else
#      session[:key] = "hello!"
    end
  end


  def update()
    uids = params["uids"] || []
    service = params["service"] || nil

    self.supported_types
    @contacts = []
    resource = Device.where(name: 'SOCIAL_LINK').first.resource
    Device.where(name: resource[:contacts]).find_each do |address_book|
      address_book.state[:contacts].each do |contact|
        @contacts << contact
      end
    end
    
    @contacts.shuffle.each do |contact|
      vcard = VCardigan.parse(contact[:card])
      uid = vcard.uid.first.values[0]
      if uids.include?(uid) || uids == []
        logger.info "Indexing #{vcard.fn.first.values[0]}"
        pc = ProfilesController.new
        tc = SocialLinkContact.where(uid: uid).first

        if service.nil?
          @person = pc.fetch_posts(uid)
        else
          types = []
          @types.each do |type|
            types << type if type.start_with?(service.to_s.downcase)
          end
          logger.info "TYPES: #{types.to_s}"
          filters = {'types' => types}
          puts filters.to_s
          @person = pc.fetch_posts(uid, filters)
        end

        # This avoids the need for a complete rescan when one of many services updates. This way, if we know that X just updated, we
        # can rescan X but ignore Y, as we know those values haven't changed.

        $debug = @person[:last_timestamps]

        activity_cache = tc.activity_cache || {}
        @person[:last_timestamps].each do |key, value|
          if @person[:last_timestamps][key].count > 0 && key
            activity_cache[key] = @person[:last_timestamps][key].sort[-1]
          end
        end
        tc.update(last_updated: @person[:timestamps][0] || 0, activity_cache: activity_cache)

        last_notification_activity = 0
        activity_cache.each do |key, value|
          # SocialLink is not a chat client. It should not have new notifications for a person based on chat logs that just came in.
          # However, it shouldn't sort someone as "last updated X years ago" if they talk to you daily. To solve this, we separate
          # last DB row insertion (last_updated) from last unseen thing (last_notification_activity)
          next if [nil, "matrix_event", "android_sms", "mamirc_event", "facebook_message"].include?(key)

          # Finally, we also filter out things that we currently view by browsing their respective websites, where SocialLink does
          # not currently fully replace browsing it. We shouldn't get notifications for things we've already seen elsewhere.
          next if ["facebook_album", "facebook_post", "facebook_photo", "facebook_photo_of"].include?(key)

          last_notification_activity = activity_cache[key] if (activity_cache[key] > last_notification_activity)
        end

        tc.update(last_notification_activity: last_notification_activity)
      end
    end ; nil
    render plain: 'done'
  end
end
