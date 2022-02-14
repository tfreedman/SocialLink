class PostsController < ApplicationController
  def show
    if params["post_type"] == "fbid" || params["post_type"] == "pixiv"

      # Normally, we'd be able to render a page pretty easily given just the post's DB ID and table.
      # However, we actually store things as <id, account> so that all images belonging to a person
      # go in that person's folder. This means we have to select a random person to pull the image from,
      # if we only have an ID.

      @title = "View Post"
      if params["post_type"] == "fbid"
        post = FBID.where(fbid: params["post_id"]).first
        post_type = 'fbid'
      elsif params["post_type"] == "pixiv"
        post = PixivPost.where(post_id: params["post_id"]).first
        post_type = 'pixiv'
      end

      if post
        contacts = []
        address_books = YAML.load(File.read("contacts.yml"))
        address_books.each do |key, value|
          value.each do |contact|
            contacts << {contact: contact, address_book: key}
          end
        end

        facebook_accounts = []
        pixiv_accounts = []

        contacts.each do |contact|
          vcard = VCardigan.parse(contact[:contact][:card])
          if vcard.field('x-socialprofile')
            vcard.field('x-socialprofile').each do |profile|
              if profile.value.include?("facebook.com/")
                facebook_accounts << profile.value.split('facebook.com/')[1].split('/')[0]
              elsif profile.value.include?("pixiv.net/")
                pixiv_accounts << profile.value.split('pixiv.net/')[1].split('id=')[1]
              end
            end
          end

          if post_type == 'fbid' && facebook_accounts.include?(post.fb_account)
            @person = {name: vcard.fn.first.values[0]}
            @post = {content: post, sort_time: post.estimated_timestamp || 0, type: 'facebook_post'}
            details = true
            break
          end

          if post_type == 'pixiv' && pixiv_accounts.include?(post.pixiv_member_id)
            @person = {name: vcard.fn.first.values[0]}
            begin
              json = JSON.parse(post[:json])
              @post = {sort_time: Time.parse(json["body"]["createDate"]).to_i, type: 'pixiv', content: post}
            rescue
            end
            details = true
            break
          end
        end
      else
        ':('
      end
    end      
  end
end
