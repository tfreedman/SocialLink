class ProfilesController < ApplicationController
  def update
    SocialLinkContact.where(uid: params["uuid"]).first.update(notification_delay: params["notification_delay"], youtube_auto_download: params["youtube_auto_download"])
  end

  def posts
    page_number = params["page"].to_i || 1
    pagination = 100

    @person = fetch_posts(params["uuid"], params["filters"] || {})
    if params["update_filters"] == "true" && params["filters"]
      SocialLinkContact.where(uid: params["uuid"]).first.update(default_filters: params["filters"]["types"])
    end
    total_count = @person[:posts].count
    timestamps = []
    @person[:posts].each do |post|
      timestamps << post[:sort_time]
    end
    @person[:timestamps] = timestamps
    filtered_page_count = (@person[:posts].count / pagination.to_f).ceil
    filtered_page_count = 1 if filtered_page_count == 0
    response.headers['Filtered-Page-Count'] = filtered_page_count
    @person[:posts] = @person[:posts][((page_number - 1) * pagination)..((page_number) * pagination)]
    
    # This is a hack to reduce memory usage
    @person[:posts].each do |post|
      if post[:id] && post[:type].start_with?('facebook')
        post[:content] = FBID.where(id: post[:id]).first
      elsif post[:id] && post[:type].start_with?('twitter')
        post[:content] = TwitterTweet.where(id: post[:id]).first
      elsif post[:id] && post[:type].start_with?('tumblr')
        post[:content] = TumblrPost.where(id: post[:id]).first
        x = Nokogiri::HTML.parse(post[:content].xml_dump)
        text = x.css('tumblr regular-body').text
        post[:text] = text
      elsif post[:id] && post[:type].start_with?('deviantart')
        post[:content] = DeviantartPost.where(id: post[:id]).first
      end
    end
    render :layout => false
  end
  
  def fetch_posts(uid, filters = {})
    @contacts = []
    Dir["#{Rails.root}/contacts/*"].each do |address_book|
      vcfs = []
      ab = File.read(address_book)
      ab.split(/(END:VCARD)/).each_slice(2) { |s| vcfs << s.join }; vcfs
      vcfs.each do |vcf|
        if vcf.include?('BEGIN:VCARD') && vcf.include?('UID')
          @contacts << {vcard: VCardigan.parse(vcf), address_book: address_book.split('/contacts/')[1].split('.vcf')[0]}
        end
      end
    end

    last_timestamps = {}

    @contacts.each do |k|
      vcard = k[:vcard]
      address_book = k[:address_book]
      if uid == vcard.uid.first.values[0]
        sc = SocialLinkContact.where(uid: vcard.uid.first.values[0]).first
        query_cache = sc.query_cache || {}

        bluesky_accounts = []
        youtube_accounts = []
        reddit_accounts = []
        instagram_accounts = []
        deviantart_accounts = []
        pixiv_accounts = []
        tumblr_accounts = []
        facebook_accounts = []
        twitter_accounts = []
        phone_numbers = []
        matrix_accounts = []
        mastodon_accounts = []
        ao3_accounts = []
        webcomics = []
        accounts = []
        discord_guilds = []

        if vcard.field('x-socialprofile')
          vcard.field('x-socialprofile').each do |profile|
            if profile.value.include?("youtube.com")
              accounts << {service: 'youtube', url: profile.value}
              youtube_accounts << profile.value.split('youtube.com/channel/')[1]
            elsif profile.value.include?("bsky.app/profile/")
              accounts << {service: 'bluesky', url: profile.value}
              bluesky_accounts << profile.value.split('bsky.app/profile/')[1]
            elsif profile.value.include?("wc://")
              accounts << {service: 'webcomic', url: profile.value.split('://')[1].split('#')[0]}
              webcomics << profile.value.split('#')[1]
            elsif profile.value.include?("reddit.com/user/") || profile.value.include?("reddit.com/u/")
              accounts << {service: 'reddit', url: profile.value}
              reddit_accounts << profile.value.split('/')[-1]
            elsif profile.value.include?("discord.com/channels/")
              accounts << {service: 'discord', url: profile.value}
              discord_guilds << profile.value.split('discord.com/channels/')[1].split('/')[0].to_i
            elsif profile.value.include?("instagram.com/")
              accounts << {service: 'instagram', url: profile.value}
              ig = InstagramAccount.where(username: profile.value.split('instagram.com/')[1].split('/')[0]).first
              if ig
                instagram_accounts << ig.instagram_id
              end
            elsif profile.value.include?("deviantart.com/")
              accounts << {service: 'deviantart', url: profile.value}
              deviantart_accounts << profile.value.split('deviantart.com/')[1].split('/')[0].downcase
            elsif profile.value.count('@') == 2
              accounts << {service: 'mastodon', url: 'https://' + profile.value.split('@')[2] + '/@' + profile.value.split('@')[1]}
              ma = MastodonAccount.where(username: profile.value).first
              if ma
                mastodon_accounts << ma.user_id
              end
            elsif profile.value.include?("archiveofourown.org/users/")
              accounts << {service: 'ao3', url: profile.value}
              ao3_accounts << profile.value.split('/users/')[1].split('/')[0]
            elsif profile.value.include?("pixiv.net/")
              accounts << {service: 'pixiv', url: profile.value}
              if profile.value.include?("pixiv.net/member")
                pixiv_accounts << profile.value.split('id=')[1] # old format
              elsif profile.value.include?('pixiv.net/') && profile.value.include?('users/')
                pixiv_accounts << profile.value.split('users/')[1].split('/')[0] # new format
              end
            elsif profile.value.include?("tumblr.com")
              accounts << {service: 'tumblr', url: profile.value}
              tumblr_accounts << profile.value.split('.tumblr.com')[0].split('://')[1]
            elsif profile.value.include?("facebook.com/")
              facebook_accounts << profile.value.split('facebook.com/')[1].split('/')[0]
            elsif profile.value.include?("twitter.com/")
              twitter_accounts << profile.value.split('twitter.com/')[1].split('/')[0]
              accounts << {service: 'twitter', url: profile.value}
            end
          end
        end

        if vcard.field('tel')
          vcard.field('tel').each do |phone|
            if phone.value != nil
              accounts << {service: 'sms'}
              phone_numbers << phone.value
            end
          end
        end

        if vcard.field('impp') # legacy
          vcard.field('impp').each do |profile|
            if profile.value.include?("@facebook_")
              if profile.value.include?('%3A')
                url = profile.value.split('%3A')[0].split('@facebook_')[1]
              else
                url = profile.value.split(':')[0].split('@facebook_')[1]
              end
              facebook_accounts << url
            elsif profile.value.match(/@(.*):(.*)\.(.*)/)
              accounts << {service: 'matrix'}
              matrix_accounts << profile.value
            end
          end
        end

        facebook_accounts = facebook_accounts.uniq
        facebook_accounts.each do |fb_account|
          accounts << {service: 'facebook', url: "https://www.facebook.com/#{fb_account}"}
        end

        posts = []
        matrix_rooms = []
        
        if filters["types"].nil? || (filters["types"] && filters["types"].include?("webcomics_strip"))
          webcomics_strips = Webcomic.where(comic: webcomics, parsed: true).all
        end
        
        if filters["types"].nil? || (filters["types"] && filters["types"].include?("youtube_video"))
          youtube_videos = YoutubeVideo.where(channel_id: youtube_accounts, is_short: false).order('published_at DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("youtube_short"))
          youtube_shorts = YoutubeVideo.where(channel_id: youtube_accounts, is_short: true).order('published_at DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("reddit_comment"))
          reddit_comments = RedditComment.where(author: reddit_accounts).order('created_utc DESC').all
        end
        
        if filters["types"].nil? || (filters["types"] && filters["types"].include?("mastodon_toot"))
          mastodon_toots = MastodonToot.where(user_id: mastodon_accounts).where(reblog: nil).order('created_at DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("mastodon_retoot"))
          mastodon_retoots = MastodonToot.where(user_id: mastodon_accounts).where.not(reblog: nil).order('created_at DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("bluesky_post"))
          bluesky_ids = BlueskyAccount.where(uid: uid).pluck(:did)
          bluesky_posts = BlueskyPost.where(user_did: bluesky_ids).order('sort_at DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("ao3_work"))
          ao3_works = AO3Work.where(username: ao3_accounts).order('last_updated DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("instagram_post"))
          instagram_posts = InstagramPost.where(instagram_user_id: instagram_accounts).order('timestamp DESC').all
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("instagram_story"))
          instagram_stories = InstagramStory.where(instagram_user_id: instagram_accounts).order('timestamp DESC').all
        end
        
        if filters["types"].nil? || (filters["types"] && filters["types"].include?("deviantart_post"))
          last_timestamps['deviantart_post'] = []
          DeviantartPost.where(username: deviantart_accounts, parsed: true).pluck(:id, :pubdate).each do |id, pubdate|
            posts << {sort_time: pubdate.to_i, type: 'deviantart_post', id: id}
            last_timestamps['deviantart_post'] << pubdate.to_i
          end
        end

        if filters["types"].nil? || (filters["types"] && 
        (filters["types"].include?("facebook_photo") || filters["types"].include?("facebook_photo_of") || filters["types"].include?("facebook_post") ||
        filters["types"].include?("facebook_album")))
          facebook_authored_edges = FBIDEdge.where(from: facebook_accounts, relationship: 'AUTHORED').pluck(:to)
        end
  
        if filters["types"].nil? || (filters["types"] && (filters["types"].include?("facebook_photo_of") || filters["types"].include?("facebook_photo")))
          facebook_photos_of_edges = FBIDEdge.where(from: facebook_accounts, relationship: 'PHOTOTAGGEE_IS_IN_PHOTO').pluck(:to)
          if facebook_photos_of_edges.count > 0
            if !query_cache[:facebook_photos_of]
              query_cache[:facebook_photos_of] = []
              FBID.where(fbid_type: 'photo', fb_account: facebook_accounts, fbid: facebook_photos_of_edges).find_each(batch_size: 100) do |f|
                if f.mobile_html && !f.mobile_html.include?('The page you requested was not found')
                  query_cache[:facebook_photos_of] << f.id
                end
              end
              sc.update(query_cache: query_cache)
            end
            last_timestamps['facebook_photo_of'] = []
            facebook_photos_of = []
            FBID.where(id: query_cache[:facebook_photos_of]).pluck(:id, :estimated_timestamp, :fbid).each do |id, estimated_timestamp, fbid|
              posts << {sort_time: estimated_timestamp || 0, type: 'facebook_photo_of', id: id}
              facebook_photos_of << fbid
              last_timestamps['facebook_photo_of'] << (estimated_timestamp || 0)
            end
          end

          if facebook_authored_edges.count > 0
            if !query_cache[:facebook_photos]
              query_cache[:facebook_photos] = []
              FBID.where(fbid_type: 'photo', fb_account: facebook_accounts, fbid: facebook_authored_edges).where.not(fbid: facebook_photos_of).find_each(batch_size: 100) do |f|
                if f.mobile_html && !f.mobile_html.include?('The page you requested was not found')
                  query_cache[:facebook_photos] << f.id
                end
              end
              sc.update(query_cache: query_cache)
            end
            last_timestamps['facebook_photo'] = []
            FBID.where(id: query_cache[:facebook_photos]).pluck(:id, :estimated_timestamp).each do |id, estimated_timestamp|
              posts << {sort_time: estimated_timestamp || 0, type: 'facebook_photo', id: id}
              last_timestamps['facebook_photo'] << (estimated_timestamp || 0)
            end
          end
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("facebook_post"))
          if facebook_authored_edges.count > 0
            if !query_cache[:facebook_posts_authored]
              query_cache[:facebook_posts_authored] = []
              FBID.where(fbid_type: 'post', fb_account: facebook_accounts, fbid: facebook_authored_edges).find_each(batch_size: 100) do |f|
                if f.mobile_html && !f.mobile_html.include?('The page you requested was not found') && FBIDEdge.where(from: f.fbid, relationship: 'HAS_CNAME_FROM').first.nil?
                  query_cache[:facebook_posts_authored] << f.id
                end
              end
              sc.update(query_cache: query_cache)
            end
            last_timestamps['facebook_post'] = []
            FBID.where(id: query_cache[:facebook_posts_authored]).pluck(:id, :estimated_timestamp).each do |id, estimated_timestamp|
              posts << {sort_time: estimated_timestamp || 0, type: 'facebook_post', id: id}
              last_timestamps['facebook_post'] << (estimated_timestamp || 0)
            end
          end
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("facebook_album"))
          if facebook_authored_edges.count > 0
            if !query_cache[:facebook_albums_authored]
              query_cache[:facebook_albums_authored] = []
              FBID.where(fbid_type: 'album', fb_account: facebook_accounts, fbid: facebook_authored_edges).find_each(batch_size: 100) do |f|
                if f.mobile_html && !f.mobile_html.include?('The page you requested was not found')
                  query_cache[:facebook_albums_authored] << f.id
                end
              end
              sc.update(query_cache: query_cache)
            end
            last_timestamps['facebook_album'] = []
            FBID.where(id: query_cache[:facebook_albums_authored]).pluck(:id, :estimated_timestamp).each do |id, estimated_timestamp|
              posts << {sort_time: estimated_timestamp || 0, type: 'facebook_album', id: id}
              last_timestamps['facebook_album'] << (estimated_timestamp || 0)
            end
          end
        end

        if filters["types"].nil? || (filters["types"] && filters["types"].include?("pixiv_post"))
          pixiv_posts = PixivPost.where(pixiv_member_id: pixiv_accounts, parsed: true).all
        end

        if filters["types"].nil? || (filters["types"] && (
          filters["types"].include?("tumblr_post-content--photo") || filters["types"].include?("tumblr_post-content--video") || filters["types"].include?("tumblr_post-content--audio") ||
          filters["types"].include?("tumblr_post-content--text") || filters["types"].include?("tumblr_post-content--answer") || filters["types"].include?("tumblr_post-content--iframe") ||
          filters["types"].include?("tumblr_post-content--chat") || filters["types"].include?("tumblr_post-content--link") || filters["types"].include?("tumblr_post-content--quote")))
          TumblrPost.where(username: tumblr_accounts, enabled: true, parsed: true).pluck(:id, :timestamp, :post_type).each do |id, timestamp, post_type|
            next if filters["types"] && !filters["types"].include?("tumblr_#{post_type}")
            posts << {sort_time: timestamp.to_i, type: "tumblr_#{post_type}", id: id}
            if last_timestamps["tumblr_#{post_type}"].nil?
              last_timestamps["tumblr_#{post_type}"] = []
            end
            last_timestamps["tumblr_#{post_type}"] << (timestamp.to_i)
          end
        end

        if filters["types"].nil? || (filters["types"] && (filters["types"].include?("twitter_tweet")) || filters["types"].include?("twitter_retweet") || filters["types"].include?("twitter_reply"))
          twitter_ids = TwitterAccount.where(uid: uid).pluck(:user_id)
          twitter_posts = []
          if filters["types"].nil? || (filters["types"] && filters["types"].include?("twitter_retweet"))
            TwitterTweet.where(user_id: twitter_ids, is_retweet: true, is_reply: false).pluck(:id, :time, :is_retweet).each do |id, time, is_retweet|
              posts << {sort_time: time.to_i, type: is_retweet ? 'twitter_retweet' : 'twitter_tweet', id: id}
              if last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')].nil?
                last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')] = []
              end
              last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')] << time.to_i
            end
          end
          if filters["types"].nil? || (filters["types"] && filters["types"].include?("twitter_tweet"))
            TwitterTweet.where(user_id: twitter_ids, is_retweet: false, is_reply: false).pluck(:id, :time, :is_retweet).each do |id, time, is_retweet|
              posts << {sort_time: time.to_i, type: is_retweet ? 'twitter_retweet' : 'twitter_tweet', id: id}
              if last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')].nil?
                last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')] = []
              end
              last_timestamps[(is_retweet ? 'twitter_retweet' : 'twitter_tweet')] << time.to_i
            end
          end
          if filters["types"].nil? || (filters["types"] && filters["types"].include?("twitter_reply"))
            TwitterTweet.where(user_id: twitter_ids, is_reply: true).pluck(:id, :time, :is_reply).each do |id, time, is_reply|
              posts << {sort_time: time.to_i, type: 'twitter_reply', id: id}
              if last_timestamps['twitter_reply'].nil?
                last_timestamps['twitter_reply'] = []
              end
              last_timestamps['twitter_reply'] << time.to_i
            end
          end
        end

        if SocialLink::Application.credentials.hindsight_integration
          if filters["types"].nil? || (filters["types"] && filters["types"].include?("android_mms"))
            mms_messages = AndroidMms.where(address: phone_numbers, enabled: true).or(AndroidMms.where(contact_name: vcard.fn.first.values[0], enabled: true)).order('date DESC').all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("android_sms"))
            sms_messages = AndroidSms.where(address: phone_numbers).or(AndroidSms.where(contact_name: vcard.fn.first.values[0])).order('date DESC').all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("voipms_sms"))
            voipms_sms_messages = VoipmsSms.where(contact: phone_numbers).or(VoipmsSms.where(real_name: vcard.fn.first.values[0])).order('date DESC').all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("windows_phone_sms"))
            windows_phone_sms_messages = WindowsPhoneSms.where(real_name: vcard.fn.first.values[0]).order('timestamp DESC').all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("facebook_message"))
            facebook_messages = FacebookMessage.where(room_id: FacebookRoom.where(uid: uid).pluck(:room_id)).all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("google_chat_message"))
            google_chat_messages = GoogleChatMessage.where(room: vcard.fn.first.values[0], enabled: true).order('created_date DESC').all
          end

          if filters["types"].nil? || (filters["types"] && filters["types"].include?("google_talk_message"))
            google_talk_messages = GoogleTalkMessage.where(room: vcard.fn.first.values[0], enabled: true).order('timestamp DESC').all
          end

          if vcard.fn.first.values[0].start_with?('#') # Group Chat
            room_name = vcard.fn.first.values[0][1..-1]
            
            # This is IRC - room names start with a # anyhow.
            if filters["types"].nil? || (filters["types"] && filters["types"].include?("mamirc_event"))
              mamirc_events = MamircEvent.where(real_sender: vcard.fn.first.values[0], enabled: true).or(MamircEvent.where(real_receiver: vcard.fn.first.values[0], enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("xchat_log"))
              xchat_logs = XchatLog.where(room: vcard.fn.first.values[0], enabled: true).or(XchatLog.where(real_sender: vcard.fn.first.values[0], enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("mirc_log"))
              mirc_logs = MircLog.where(room: vcard.fn.first.values[0], enabled: true).or(MircLog.where(real_sender: vcard.fn.first.values[0], enabled: true)).order('timestamp DESC').all
            end
  
            if filters["types"].nil? || (filters["types"] && filters["types"].include?("colloquy_message"))
              colloquy_messages = ColloquyMessage.where(real_sender: vcard.fn.first.values[0], enabled: true).or(ColloquyMessage.where(real_receiver: vcard.fn.first.values[0], enabled: true)).order('timestamp DESC').all
            end

            # Not IRC - ignore the #
            if filters["types"].nil? || (filters["types"] && filters["types"].include?("microsoft_teams_message"))
              microsoft_teams_conversations = MicrosoftTeamsConversation.where(display_name: room_name).pluck(:conversation_id)
              microsoft_teams_messages = MicrosoftTeamsMessage.where(conversation_id: microsoft_teams_conversations, enabled: true).order('original_arrival_time DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("pidgin_message"))
              pidgin_messages = PidginMessage.where(enabled: true, real_sender: room_name).or(PidginMessage.where(enabled: true, real_receiver: room_name)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("discord_message"))
              discord_channels = []
              DiscordChannel.where(guild_id: discord_guilds).find_each do |c|
                discord_channels << c.channel_id.to_s                
              end

              discord_messages = DiscordMessage.where(discord_channel_id: discord_channels).order('timestamp DESC').all
            end
          
            if filters["types"].nil? || (filters["types"] && filters["types"].include?("matrix_event"))
              matrix_rooms = (MatrixRoom.where(enabled: [true, nil], name: room_name).pluck(:room_id) + MatrixRoom.where(enabled: [true, nil], name: vcard.fn.first.values[0]).pluck(:room_id)).uniq
              matrix_events = MatrixEvent.where(room_id: matrix_rooms, event_type: 'm.room.message').order('origin_server_ts DESC').all
            end
          else
            if filters["types"].nil? || (filters["types"] && filters["types"].include?("matrix_event"))
              MatrixRoom.where(enabled: [true, nil]).find_each do |room|
                if room.participants
                  room.participants.each do |participant|
                    if (matrix_accounts.include?(participant) && room.participants.count == 2) || (matrix_accounts.include?(participant) && room.participants.count == 3 && room.participants.select{ |p| p.start_with?('@skypebot')}.count > 0)
                      matrix_rooms << room.room_id
                    end
                  end
                end
              end

              matrix_events = MatrixEvent.where(room_id: matrix_rooms, event_type: 'm.room.message').order('origin_server_ts DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("mamirc_event"))
              mamirc_events = MamircEvent.where(real_sender: vcard.fn.first.values[0], real_receiver: SocialLink::Application.credentials.my_name, enabled: true).or(MamircEvent.where(real_receiver: vcard.fn.first.values[0], real_sender: SocialLink::Application.credentials.my_name, enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("microsoft_teams_message"))
              microsoft_teams_conversations = MicrosoftTeamsConversation.where(display_name: vcard.fn.first.values[0]).pluck(:conversation_id)
              microsoft_teams_messages = MicrosoftTeamsMessage.where(conversation_id: microsoft_teams_conversations, enabled: true).order('original_arrival_time DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("xchat_log"))
              xchat_logs = XchatLog.where(real_sender: vcard.fn.first.values[0], real_receiver: SocialLink::Application.credentials.my_name, enabled: true).or(XchatLog.where(real_receiver: vcard.fn.first.values[0], real_sender: SocialLink::Application.credentials.my_name, enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("mirc_log"))
              mirc_logs = MircLog.where(real_sender: vcard.fn.first.values[0], real_receiver: SocialLink::Application.credentials.my_name, enabled: true).or(MircLog.where(real_receiver: vcard.fn.first.values[0], real_sender: SocialLink::Application.credentials.my_name, enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("pidgin_message"))
              pidgin_messages = PidginMessage.where(real_sender: vcard.fn.first.values[0], real_receiver: SocialLink::Application.credentials.my_name, enabled: true).or(PidginMessage.where(real_receiver: vcard.fn.first.values[0], real_sender: SocialLink::Application.credentials.my_name, enabled: true)).order('timestamp DESC').all
            end

            if filters["types"].nil? || (filters["types"] && filters["types"].include?("colloquy_message"))
              colloquy_messages = ColloquyMessage.where(real_sender: vcard.fn.first.values[0], real_receiver: SocialLink::Application.credentials.my_name, enabled: true).or(ColloquyMessage.where(real_receiver: vcard.fn.first.values[0], real_sender: SocialLink::Application.credentials.my_name, enabled: true)).order('timestamp DESC').all
            end
          end

          if mamirc_events || colloquy_messages || mirc_logs
            if (mamirc_events && mamirc_events.count > 0) || (colloquy_messages && colloquy_messages.count > 0)
              accounts << {service: 'irc'}
            end
          end

          if discord_messages
            last_timestamps['discord_message'] = []
            discord_messages.each do |m|
              posts << {sort_time: m.timestamp.to_i, type: 'discord_message', content: m}
              last_timestamps['discord_message'] << m.timestamp.to_i
            end
          end

          if microsoft_teams_messages
            last_timestamps['microsoft_teams_message'] = []
            microsoft_teams_messages.each do |m|
              posts << {sort_time: m.original_arrival_time.to_i, type: 'microsoft_teams_message', content: m}
              last_timestamps['microsoft_teams_message'] << m.original_arrival_time.to_i
            end
          end

          if matrix_events
            last_timestamps['matrix_event'] = []
            matrix_events.each do |m|
              posts << {sort_time: m.origin_server_ts / 1000, type: 'matrix_event', content: m}
              last_timestamps['matrix_event'] << m.origin_server_ts / 1000
            end
          end

          if google_talk_messages
            last_timestamps['google_talk_message'] = []
            google_talk_messages.each do |g|
              posts << {sort_time: g.timestamp.to_i, type: 'google_talk_message', content: g}
              last_timestamps['google_talk_message'] << g.timestamp.to_i
            end
          end

          if google_chat_messages
            last_timestamps['google_chat_message'] = []
            google_chat_messages.each do |g|
              posts << {sort_time: g.created_date, type: 'google_chat_message', content: g}
              last_timestamps['google_chat_message'] << g.created_date
            end
          end

          if voipms_sms_messages
            last_timestamps['voipms_sms'] = []
            voipms_sms_messages.each do |v|
              posts << {sort_time: v.date.to_i, type: 'voipms_sms', content: v}
              last_timestamps['voipms_sms'] << v.date
            end
          end

          if windows_phone_sms_messages
            last_timestamps['windows_phone_sms'] = []
            windows_phone_sms_messages.each do |w|
              posts << {sort_time: w.timestamp, type: 'windows_phone_sms', content: w}
              last_timestamps['windows_phone_sms'] << w.timestamp
            end
          end

          if pidgin_messages
            last_timestamps['pidgin_message'] = []
            pidgin_messages.each do |p|
              posts << {sort_time: p.timestamp, type: 'pidgin_message', content: p}
              last_timestamps['pidgin_message'] << p.timestamp
            end
          end

          if colloquy_messages
            last_timestamps['colloquy_message'] = []
            colloquy_messages.each do |c|
              posts << {sort_time: c.timestamp, type: 'colloquy_message', content: c}
              last_timestamps['colloquy_message'] << c.timestamp
            end
          end

          if mamirc_events
            last_timestamps['mamirc_event'] = []
            mamirc_events.each do |m|
              posts << {sort_time: m.timestamp / 1000, type: 'mamirc_event', content: m}
              last_timestamps['mamirc_event'] << m.timestamp / 1000
            end
          end

          if mirc_logs
            last_timestamps['mirc_log'] = []
            mirc_logs.each do |m|
              posts << {sort_time: m.timestamp.to_i, type: 'mirc_log', content: m}
              last_timestamps['mirc_log'] << m.timestamp.to_i
            end
          end

          if xchat_logs
            last_timestamps['xchat_log'] = []
            xchat_logs.each do |x|
              posts << {sort_time: x.timestamp.to_i, type: 'xchat_log', content: x}
              last_timestamps['xchat_log'] << x.timestamp.to_i
            end
          end

          if mastodon_toots
            last_timestamps['mastodon_toot'] = []
            mastodon_toots.each do |m|
              posts << {sort_time: m.created_at.to_i, type: 'mastodon_toot', content: m}
              last_timestamps['mastodon_toot'] << m.created_at.to_i
            end
          end

          if mastodon_retoots
            last_timestamps['mastodon_retoot'] = []
            mastodon_retoots.each do |m|
              posts << {sort_time: m.created_at.to_i, type: 'mastodon_retoot', content: m}
              last_timestamps['mastodon_retoot'] << m.created_at.to_i
            end
          end

          hangouts_conversations = []
          HangoutsConversation.find_each do |conversation|
            conversation.participant_data.each do |p|
              if p["fallback_name"] == vcard.fn.first.values[0]
                hangouts_conversations << conversation.conversation_id
              end
            end
          end

          if hangouts_conversations.count > 0
            accounts << {service: 'hangouts'}
          end
  
          if sms_messages
            last_timestamps['android_sms'] = []
            sms_messages.each do |s|
              posts << {sort_time: s.date / 1000, type: 'android_sms', content: s}
              last_timestamps['android_sms'] << s.date / 1000
            end
          end

          if mms_messages
            last_timestamps['android_mms'] = []
            mms_messages.each do |s|
              posts << {sort_time: s.date / 1000, type: 'android_mms', content: s}
              last_timestamps['android_mms'] << s.date / 1000
            end
          end
  
          if filters["types"].nil? || (filters["types"] && filters["types"].include?("hangouts_event"))
            hangouts_events = HangoutsEvent.where(conversation_id: hangouts_conversations, enabled: true).order('timestamp DESC').all
          end
  
          if hangouts_events
            last_timestamps['hangouts_event'] = []
            hangouts_events.each do |h|
              posts << {sort_time: (h.timestamp / 1000000).to_i, type: 'hangouts_event', content: h}
              last_timestamps['hangouts_event'] << (h.timestamp / 1000000).to_i
            end
          end
        end

        if bluesky_posts
          last_timestamps['bluesky_post'] = []
          bluesky_posts.each do |b|
            posts << {sort_time: b.sort_at.to_i, type: 'bluesky_post', content: b}
            last_timestamps['bluesky_post'] << b.sort_at.to_i
          end
        end

        if ao3_works
          last_timestamps['ao3_work'] = []
          ao3_works.each do |a|
            posts << {sort_time: a.last_updated.to_time.to_i, type: 'ao3_work', content: a}
            last_timestamps['ao3_work'] << a.last_updated.to_time.to_i
          end
        end

        if youtube_videos
          last_timestamps['youtube_video'] = []
          youtube_videos.each do |v|
            posts << {sort_time: v.published_at.to_i, type: 'youtube_video', content: v}
            last_timestamps['youtube_video'] << v.published_at.to_i
          end
        end

        if youtube_shorts
          last_timestamps['youtube_short'] = []
          youtube_shorts.each do |v|
            posts << {sort_time: v.published_at.to_i, type: 'youtube_short', content: v}
            last_timestamps['youtube_short'] << v.published_at.to_i
          end
        end

        if facebook_messages
          last_timestamps['facebook_message'] = []
          facebook_messages.each do |f|
            posts << {sort_time: f.timestamp / 1000, type: 'facebook_message', content: f}
            last_timestamps['facebook_message'] << (f.timestamp / 1000)
          end
        end

        if reddit_comments
          last_timestamps['reddit_comment'] = []
          reddit_comments.each do |r|
            posts << {sort_time: r.created_utc, type: 'reddit_comment', content: r}
            last_timestamps['reddit_comment'] << r.created_utc
          end
        end
  
        if instagram_posts
          last_timestamps['instagram_post'] = []
          instagram_posts.each do |i|
            if i.json # Hack
              posts << {sort_time: i.timestamp, type: 'instagram_post', folder: InstagramAccount.where(instagram_id: i.instagram_user_id).first.username, content: i}
              last_timestamps['instagram_post'] << i.timestamp
            end
          end
        end

        if instagram_stories
          last_timestamps['instagram_story'] = []
          instagram_stories.each do |s|
            posts << {sort_time: s.timestamp, type: 'instagram_story', folder: InstagramAccount.where(instagram_id: s.instagram_user_id).first.username, content: s}
            last_timestamps['instagram_story'] << s.timestamp
          end
        end

        if webcomics_strips
          last_timestamps['webcomics_strip'] = []
          webcomics_strips.each do |w|
            posts << {sort_time: w.date.to_time.to_i, type: 'webcomics_strip', content: w}
            last_timestamps['webcomics_strip'] << w.date.to_time.to_i
          end
        end

        if pixiv_posts
          last_timestamps['pixiv_post'] = []
          pixiv_posts.each do |p|
            posts << {sort_time: p.created_at.to_i, type: 'pixiv_post', content: p}
            last_timestamps['pixiv_post'] << p.created_at.to_i
          end
        end

        posts = posts.sort_by{ |post|
          post[:sort_time]
        }.reverse

        timestamps = []
        posts.each do |post|
          timestamps << post[:sort_time]
        end
        @person = {name: vcard.fn.first.values[0], uid: uid, vcard: vcard, posts: posts.uniq, post_count: posts.count, accounts: accounts, timestamps: timestamps, address_book: address_book, last_timestamps: last_timestamps}
      end
    end
    return @person
  end


  def index
    @contacts = []
    @pagename = 'index'
    @title = 'Home'

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

    @people = []
    @recently_updated = []
    @contacts.each do |vcard|
      person = {name: vcard.fn.first.values[0], uid: vcard.uid.first.values[0], vcard: vcard, recently_updated: false}
      sc = SocialLinkContact.where(uid: vcard.uid.first.values[0]).first
      if sc.nil?
        sc = SocialLinkContact.create(uid: vcard.uid.first.values[0], last_updated: 0, last_atime: 0)
      end
      person[:last_updated] = sc.last_updated

      if (sc.last_notification_activity > sc.last_atime) && (sc.notification_delay + sc.last_atime < Time.now.to_i)
        person[:recently_updated] = true
        @recently_updated << person
      else
        @people << person
      end
    end

    @recently_updated = @recently_updated.sort_by { |person|
      person[:last_updated]
    }.reverse

    @all_people = @people.sort_by { |person|
      person[:name].downcase
    }
  end

  def show
    @pagename = 'profiles_show'
    @page_number = params["page_number"].to_i || 1

    @prev_page_url = ""
    @next_page_url = ""


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

    @contacts.each do |vcard|
      uid = vcard.uid.first.values[0]

      if uid == params["uuid"]
        @person = fetch_posts(uid, {})

        if vcard.photo
          @person[:photo] = vcard.photo[0].values[0]
        else
          @person[:photo] = nil
        end

        @filters = SocialLinkContact.where(uid: uid).first.default_filters || ApplicationController::SUPPORTED_TYPES
      end
    end

    post_count = @person[:posts].count
    @pagination = 100

    if @page_number < 1
      @page_number = 1
    elsif @page_number > (post_count/ @pagination.to_f).ceil + 1
      @page_number = (post_count / @pagination.to_f).ceil + 1
    end

    if @page_number == 1
      @sc = SocialLinkContact.where(uid: @person[:uid]).first
      @sc.update(last_atime: Time.now.to_i)
    end

    @timeline = {dates: {}, service_counts: {}}
    @person[:posts].each do |post|
      if @timeline[:service_counts][post[:type]].nil?
        @timeline[:service_counts][post[:type]] = 0
      end
      @timeline[:service_counts][post[:type]] += 1
    end
    @person[:posts] = @person[:posts].slice((@page_number.to_i - 1) * @pagination, @pagination)

    # This is a hack to reduce memory usage
    @person[:posts].each do |post|
      if post[:id] && post[:type].start_with?('facebook')
        post[:content] = FBID.where(id: post[:id]).first
      elsif post[:id] && post[:type].start_with?('twitter')
        post[:content] = TwitterTweet.where(id: post[:id]).first
      elsif post[:id] && post[:type].start_with?('tumblr')
        post[:content] = TumblrPost.where(id: post[:id]).first
        x = Nokogiri::HTML.parse(post[:content].xml_dump)
        text = x.css('tumblr regular-body').text
        post[:text] = text
      elsif post[:id] && post[:type].start_with?('deviantart')
        post[:content] = DeviantartPost.where(id: post[:id]).first
      end
    end

    @person[:timestamps].each_with_index do |timestamp, index|
      time = Time.at(timestamp)
      if @timeline[:dates][time.year].nil?
        @timeline[:dates][time.year] = {}
      end
      if !@timeline[:dates][time.year][time.month]
        @timeline[:dates][time.year][time.month] = (index / @pagination.to_f).ceil
      end
    end
    @title = @person[:name]
  end

  def statistics
    @pagename = 'statistics'
    @title = 'Statistics'

    @dfp = {} #Dangling Forward Pointers
    @dbp = {} #Dangling Backwards Pointers
    @timestamps = {}
    @dfp[:facebook_messenger] = []
    @dfp[:hangouts] = []
    FacebookRoom.where(uid: nil, thread_type: 'Regular').find_each do |room|
      @dfp[:facebook_messenger] << {room: room.room_id, name: room.real_name}
    end

    @bad_uids = []
    @bad_fb_contacts = {}
    contacts_raw = []
    contacts = []
    contact_uid_to_name = {}
    contact_name_to_uid = {}

    mxid_to_name = {}

    vcfs = []
    Dir["#{Rails.root}/contacts/*"].each do |address_book|
      ab = File.read(address_book)
      ab.split(/(END:VCARD)/).each_slice(2) { |s| vcfs << s.join }; vcfs
    end
    vcfs.each do |vcf|
      if vcf.include?('BEGIN:VCARD') && vcf.include?('UID')
        contacts_raw << VCardigan.parse(vcf)
      end
    end

    contacts_raw.each do |vcard|
      name = vcard.fn.first.values[0]
      uid = vcard.uid.first.values[0]
      contacts << {name: name, uid: uid, contact: vcard}
      contact_uid_to_name[uid] = name #for dfps
      contact_name_to_uid[name] = uid

      if vcard.field('impp')
        vcard.field('impp').each do |profile|
          if profile.value.match(/@(.*):(.*)\.(.*)/)
            mxid_to_name[profile.value] = name
          end
        end
      end

      if vcard.uid.first.values[0].gsub(/[^0-9a-z\-]/i, '').length != vcard.uid.first.values[0].length
        @bad_uids << {name: vcard.fn.first.values[0], uid: vcard.uid.first.values[0]}
      end
      if vcard.field('impp') # legacy
        vcard.field('impp').each do |profile|
          if profile.value.downcase.include?("%3a")
            @bad_fb_contacts[vcard.fn.first.values[0]] = vcard.uid.first.values[0]
          end
        end
      end
    end

    @dfp[:folders] = {}
    contacts.each do |contact|
      @dfp[:folders][contact[:name]] = (File.exist?(SocialLink::Application.credentials.asset_path + contact[:name]) && File.directory?(SocialLink::Application.credentials.asset_path + contact[:name]))
    end

    @dbp[:folders] = {}
    Dir.foreach(SocialLink::Application.credentials.asset_path) do |name|
      next if name == '.' or name == '..' or !File.directory?(SocialLink::Application.credentials.asset_path + name)
      @dbp[:folders][name] = (contact_name_to_uid[name] || false)
    end

    HangoutsConversation.find_each do |conversation|
      conversation.participant_data.each do |participant|
        if participant[:fallback_name] != SocialLink::Application.credentials.my_name && contact_name_to_uid[participant["fallback_name"]].nil?
          @dfp[:hangouts] << {conversation_id: conversation.conversation_id, name: participant["fallback_name"]}
        end
      end
    end

    instagram_urls = {}
    instagram_files = {}
    InstagramPost.find_each do |post|
      begin
        json = JSON.parse(post.json)
        if json['__typename'] == 'GraphVideo'
          instagram_urls[json["video_url"].split('/')[-1].split('?')[0]] = nil
        elsif json['__typename'] == 'GraphImage'
          instagram_urls[json["display_url"].split('/')[-1].split('?')[0]] = nil
        elsif json['__typename'] == 'GraphSidecar'
          json['edge_sidecar_to_children']['edges'].each do |edge|
            if edge['node']['__typename'] == 'GraphImage'
              instagram_urls[edge['node']['display_url'].split('/')[-1].split('?')[0]] = nil
            elsif edge['node']['__typename'] == 'GraphVideo'
              instagram_urls[edge['node']['video_url'].split('/')[-1].split('?')[0]] = nil
            end
          end
        end
      rescue
      end
    end

    InstagramStory.find_each do |post|
      instagram_urls[post.filename] = nil  
    end

    Dir.foreach(SocialLink::Application.credentials.asset_path) do |name|
      next if name == '.' or name == '..' or !File.directory?(SocialLink::Application.credentials.asset_path + name)
      Dir.foreach(SocialLink::Application.credentials.asset_path + name) do |service|
        next if service != "Instagram"
        Dir.foreach(SocialLink::Application.credentials.asset_path + "#{name}/Instagram/") do |account|
          next if account == '.' or account == '..' or !File.directory?(SocialLink::Application.credentials.asset_path + "#{name}/Instagram/#{account}")
          Dir.foreach(SocialLink::Application.credentials.asset_path + "#{name}/Instagram/#{account}") do |file|
            next if file == '.' or file == '..'
            instagram_files[file] = SocialLink::Application.credentials.asset_path + "#{name}/Instagram/#{account}/#{file}"
          end
        end
      end
    end

    @dfp[:instagram_posts] = instagram_urls.reject { |k,v|  instagram_files.has_key? k}
    @dbp[:instagram_posts] = instagram_files.reject { |k,v|  instagram_urls.has_key? k}

    @dfp[:windows_phone] = []
    WindowsPhoneSms.find_each do |message|
      if message[:real_name] && contact_name_to_uid[message[:real_name]].nil?
        @dfp[:windows_phone] << message[:real_name]
      end
    end
    @dfp[:windows_phone] = @dfp[:windows_phone].uniq

    @dfp[:pidgin] = []
    PidginMessage.find_each do |message|
      if message[:real_sender] && contact_name_to_uid[message[:real_sender]].nil?
        @dfp[:pidgin] << message[:real_sender]
      elsif message[:real_receiver] && contact_name_to_uid[message[:real_receiver]].nil?
        @dfp[:pidgin] << message[:real_receiver]
      end
    end
    @dfp[:pidgin] = @dfp[:pidgin].uniq

    @dfp[:colloquy] = []
    ColloquyMessage.find_each do |message|
      if message[:real_sender] && contact_name_to_uid[message[:real_sender]].nil?
        @dfp[:colloquy] << message[:real_sender]
      elsif message[:real_receiver] && contact_name_to_uid[message[:real_receiver]].nil?
        @dfp[:colloquy] << message[:real_receiver]
      end
    end
    @dfp[:colloquy] = @dfp[:colloquy].uniq

    @dfp[:mamirc] = []
    MamircEvent.find_each do |event|
      if event[:real_sender] && contact_name_to_uid[event[:real_sender]].nil?
        @dfp[:mamirc] << event[:real_sender]
      elsif event[:real_receiver] && contact_name_to_uid[event[:real_receiver]].nil?
        @dfp[:mamirc] << event[:real_receiver]
      end
    end
    @dfp[:mamirc] = @dfp[:mamirc].uniq

    @dfp[:matrix] = []
    MatrixRoom.where(enabled: [true, nil]).find_each do |room|
      if room.name
        if contact_name_to_uid[room.name].nil?
          @dfp[:matrix] << room.name
        end
      else
        room.participants.each do |participant|
          @dfp[:matrix] << participant if mxid_to_name[participant].nil?
        end
      end
    end
    @dfp[:matrix] = @dfp[:matrix].uniq

    @timestamps[:colloquy] = ColloquyMessage.pluck(:timestamp).sort
    @timestamps[:mamirc] = MamircEvent.pluck(:timestamp).sort
    @timestamps[:windows_phone] = WindowsPhoneSms.pluck(:timestamp).sort
    @timestamps[:facebook_messenger] = FacebookMessage.pluck(:timestamp).sort
    @timestamps[:hangouts] = HangoutsEvent.pluck(:timestamp).sort
    @timestamps[:pidgin] = PidginMessage.pluck(:timestamp).sort
  end
end
