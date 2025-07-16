class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [:update]
  before_action :check_session_keys, except: [:update, :auth]
  before_action :service_name_path_cache_update

  SUPPORTED_TYPES = [
    "android_mms",
    "android_sms",
    "ao3_work",
    "bluesky_post",
    "colloquy_message",
    "deviantart_post",
    "discord_message",
    "facebook_message",
    "facebook_post",
    "facebook_photo",
    "facebook_photo_of",
    "facebook_album",
    "google_chat_message",
    "google_talk_message",
    "hangouts_event",
    "instagram_post",
    "instagram_story",
    "lounge_log",
    "mamirc_event",
    "mastodon_toot",
    "mastodon_retoot",
    "matrix_event",
    "microsoft_teams_message",
    "mirc_log",
    "pidgin_message",
    "pixiv_post",
    "reddit_comment",
    "tumblr_post-content--photo",
    "tumblr_post-content--video",
    "tumblr_post-content--audio",
    "tumblr_post-content--text",
    "tumblr_post-content--answer",
    "tumblr_post-content--iframe",
    "tumblr_post-content--chat",
    "tumblr_post-content--link",
    "tumblr_post-content--quote",
    "twitter_tweet",
    "twitter_reply",
    "twitter_retweet",
    "voipms_sms",
    "windows_phone_sms",
    "webcomics_strip",
    "xchat_log",
    "youtube_video",
    "youtube_short"
  ]

  # This variable exists so that SocialLink's ERB views can be loaded directly into Hindsight
  SOCIALLINK_BASE_MEDIA_URL = ''

  def auth
    if params[:key] == SocialLink::Application.credentials.auth_token
#      session[:key] = "hello!"
      render plain: ":)" and return
    end
    render plain: ":(" and return
  end

  # TODO: add a real authentication solution
  def check_session_keys
    if !session[:key] || (session[:key] && session[:key] != "hello!")
      render :json => {:status=>false}, :status => 401 and return
    end
  end

  def service_name_path_cache_update
    snpc = ServiceNamePathCache.where(service: 'sociallink').first

    oldest_file = Time.at(0)
    Dir["#{Rails.root}/contacts/*"].each do |address_book|
      if oldest_file == Time.at(0)
        oldest_file = File.mtime(address_book)
      end
      if oldest_file < File.mtime(address_book)
        oldest_file = File.mtime(address_book)
      end
    end

    return if snpc && snpc.updated_at >= oldest_file
    contacts = []

    start_time = Time.now

    vcfs = []
    Dir["#{Rails.root}/contacts/*"].each do |address_book|
      ab = File.read(address_book)
      ab.split(/(END:VCARD)/).each_slice(2) { |s| vcfs << s.join }; vcfs
    end
    vcfs.each do |vcf|
      if vcf.include?('BEGIN:VCARD') && vcf.include?('UID')
        contacts << VCardigan.parse(vcf)
      end
    end

    contacts.each do |vcard|
      uid = vcard.uid.first.values[0]

      if vcard.field('impp')
        vcard.field('impp').each do |profile|
          if profile.value.match(/@(.*):(.*)\.(.*)/)
            ServiceNamePathCache.create(uid: uid, service: 'Matrix', name: vcard.fn.first.values[0], username: profile.value, updated_at: start_time)
          end
        end
      end

      if vcard.field('x-socialprofile')
        vcard.field('x-socialprofile').each do |profile|
          if profile.value.include?("youtube.com")
            ServiceNamePathCache.create(uid: uid, service: 'YouTube', name: vcard.fn.first.values[0], username: profile.value.split('youtube.com/channel/')[1], updated_at: start_time)
          elsif profile.value.include?("wc://")
            ServiceNamePathCache.create(uid: uid, service: 'Webcomic', name: vcard.fn.first.values[0], username: profile.value.split('#')[1], updated_at: start_time)
          elsif profile.value.include?("reddit.com/user/") || profile.value.include?("reddit.com/u/")
            ServiceNamePathCache.create(uid: uid, service: 'Reddit', name: vcard.fn.first.values[0], username: profile.value.split('/')[-1], updated_at: start_time)
          elsif profile.value.include?("instagram.com/")
            ig = InstagramAccount.where(username: profile.value.split('instagram.com/')[1].split('/')[0]).first
            if ig
              ServiceNamePathCache.create(uid: uid, service: 'Instagram', name: vcard.fn.first.values[0], username: "#{ig.username} (#{ig.instagram_id})", updated_at: start_time)
            end
          elsif profile.value.include?("deviantart.com/")
            ServiceNamePathCache.create(uid: uid, service: 'DeviantArt', name: vcard.fn.first.values[0], username: profile.value.split('deviantart.com/')[1].split('/')[0].downcase, updated_at: start_time)
          elsif profile.value.include?("pixiv.net/")
            if profile.value.include?("pixiv.net/member")
              ServiceNamePathCache.create(uid: uid, service: 'Pixiv', name: vcard.fn.first.values[0], username: profile.value.split('id=')[1], updated_at: start_time)
            elsif profile.value.include?('pixiv.net/') && profile.value.include?('users/')
              ServiceNamePathCache.create(uid: uid, service: 'Pixiv', name: vcard.fn.first.values[0], username: profile.value.split('users/')[1].split('/')[0], updated_at: start_time)
            end
          elsif profile.value.include?("tumblr.com")
            ServiceNamePathCache.create(uid: uid, service: 'Tumblr', name: vcard.fn.first.values[0], username: profile.value.split('.tumblr.com')[0].split('://')[1], updated_at: start_time)
          elsif profile.value.include?("facebook.com/")
            ServiceNamePathCache.create(uid: uid, service: 'Facebook', name: vcard.fn.first.values[0], username: profile.value.split('facebook.com/')[1].split('/')[0], updated_at: start_time)
          elsif profile.value.include?("twitter.com/")
            ServiceNamePathCache.create(uid: uid, service: 'Twitter', name: vcard.fn.first.values[0], username: profile.value.split('twitter.com/')[1].split('/')[0], updated_at: start_time)
          elsif profile.value.include?("bsky.app")
            ServiceNamePathCache.create(uid: uid, service: 'Bluesky', name: vcard.fn.first.values[0], username: profile.value.split('bsky.app/profile/')[1], updated_at: start_time)
          elsif profile.value.count('@') == 2
            ServiceNamePathCache.create(uid: uid, service: 'Mastodon', name: vcard.fn.first.values[0], username: profile.value, updated_at: start_time)
          end
        end
      end
    end
    if snpc.nil?
      ServiceNamePathCache.create(service: 'sociallink', updated_at: start_time)
    else
      snpc.update(updated_at: start_time)
    end

    ServiceNamePathCache.where('updated_at < ?', start_time).destroy_all
  end

  def update()
    uids = params["uids"] || []
    service = params["service"] || nil

    @contacts = []
    vcfs = []
    Dir["#{Rails.root}/contacts/*"].each do |address_book|
      ab = File.read(address_book)
      ab.split(/(END:VCARD)/).each_slice(2) { |s| vcfs << s.join }; vcfs
    end
    vcfs.each do |vcf|
      if vcf.include?('BEGIN:VCARD') && vcf.include?('UID')
        @contacts << VCardigan.parse(vcf)
      end
    end

    @contacts.shuffle.each do |vcard|
      uid = vcard.uid.first.values[0]
      if uids.include?(uid) || uids == []
        logger.info "Indexing #{vcard.fn.first.values[0]}"
        pc = ProfilesController.new
        tc = SocialLinkContact.where(uid: uid).first

        if service.nil?
          @person = pc.fetch_posts(uid)
        else
          types = []
          SUPPORTED_TYPES.each do |type|
            types << type if type.start_with?(service.to_s.downcase)
          end
          logger.info "TYPES: #{types.to_s}"
          filters = {'types' => types}
          puts filters.to_s
          @person = pc.fetch_posts(uid, filters)
        end

        # This avoids the need for a complete rescan when one of many services updates. This way, if we know that X just updated, we
        # can rescan X but ignore Y, as we know those values haven't changed.
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
          next if [nil, "microsoft_teams_message", "mirc_log", "google_chat_message", "matrix_event", "android_sms", "android_mms", "voipms_sms", "mamirc_event", "facebook_message"].include?(key)

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
