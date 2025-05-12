# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 0) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ao3_accounts", id: :serial, force: :cascade do |t|
    t.text "full_name"
    t.text "username"
    t.boolean "broken"
    t.boolean "enabled"
    t.timestamptz "last_scraped_at"
    t.text "uid"
  end

  create_table "ao3_works", id: :serial, force: :cascade do |t|
    t.integer "work_id"
    t.text "title", null: false
    t.date "published_at"
    t.date "last_updated"
    t.text "username"
    t.boolean "parsed"
    t.text "revisions"
    t.text "summary"
    t.timestamptz "last_checked"
  end

  create_table "bluesky_accounts", id: :serial, force: :cascade do |t|
    t.text "full_name"
    t.text "username"
    t.text "uid"
    t.text "did"
    t.boolean "broken"
    t.boolean "enabled"
    t.timestamptz "last_scraped_at"
  end

  create_table "bluesky_posts", id: :serial, force: :cascade do |t|
    t.text "user_did"
    t.text "post"
    t.text "reason"
    t.text "reply"
    t.text "uri"
    t.text "cid"
    t.text "author"
    t.text "record"
    t.text "embed"
    t.text "replyCount"
    t.text "repostCount"
    t.text "likeCount"
    t.text "quoteCount"
    t.text "indexedAt"
    t.text "labels"
    t.text "json"
    t.text "filenames"
  end

  create_table "deviantart_posts", id: :serial, force: :cascade do |t|
    t.text "username"
    t.text "post_id"
    t.boolean "parsed"
    t.text "html_dump"
    t.text "json_dump"
    t.text "filename"
    t.text "mode"
    t.timestamptz "pubdate"
    t.index ["pubdate"], name: "deviantart_posts_pubdate_idx"
    t.unique_constraint ["post_id"], name: "deviantart_posts_post_id_key"
  end

  create_table "fbid_edges", id: :serial, force: :cascade do |t|
    t.text "relationship", null: false
    t.bigint "from", null: false
    t.bigint "to", null: false
    t.index ["from"], name: "fbid_edges_from_idx"
    t.index ["relationship", "from", "to"], name: "fbid_edges_relationship_from_to_idx", unique: true
    t.index ["to"], name: "fbid_edges_to_idx"
  end

  create_table "fbids", id: :integer, default: -> { "nextval('untitled_table_id_seq1'::regclass)" }, force: :cascade do |t|
    t.text "fbid", null: false
    t.text "fb_account"
    t.text "mobile_html"
    t.text "timestamp_text"
    t.integer "estimated_timestamp"
    t.integer "timestamp"
    t.text "fbid_type"
    t.timestamptz "scraped_at"
    t.text "desktop_html"
    t.integer "reactions_scraped_count"
    t.integer "reactions_expected_count"
    t.text "parent_fbid"
    t.text "author_info"
    t.text "photo_ajax"
    t.text "payload"
    t.integer "scraped_comments"
    t.integer "total_comments"
    t.timestamptz "last_scraped_at"
    t.boolean "is_available"
    t.integer "unpacker_version", default: 0
    t.text "url"
    t.index ["fbid", "fb_account"], name: "fbids_fbid_fb_account_idx", unique: true
    t.index ["fbid"], name: "fbids_fbid_idx"
    t.index ["fbid_type"], name: "fbids_fbid_type_idx"
  end

  create_table "instagram_accounts", id: :integer, default: -> { "nextval('instagram_accounts_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "username"
    t.text "last_post"
    t.boolean "enabled", default: true
    t.text "instagram_id"
    t.timestamptz "last_story_scraped"
    t.timestamptz "last_scraped"
    t.text "last_story_scraped_via"
    t.boolean "is_now_private"
    t.text "last_good_shortcode"
    t.boolean "over_18"
  end

  create_table "instagram_posts", id: :integer, default: -> { "nextval('instagram_posts_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "instagram_id"
    t.text "instagram_user_id"
    t.integer "timestamp"
    t.text "shortcode"
    t.text "json"
    t.index ["shortcode"], name: "instagram_posts_shortcode_idx", unique: true
    t.index ["timestamp"], name: "instagram_posts_timestamp_idx"
  end

  create_table "instagram_stories", id: :integer, default: -> { "nextval('instagram_stories_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "instagram_user_id"
    t.integer "timestamp"
    t.text "filename"
    t.index ["timestamp"], name: "instagram_stories_timestamp_idx"
  end

  create_table "mastodon_accounts", id: :serial, force: :cascade do |t|
    t.text "full_name"
    t.text "username"
    t.text "uid"
    t.text "user_id"
    t.boolean "broken"
    t.boolean "enabled"
    t.timestamptz "last_scraped_at"
  end

  create_table "mastodon_toots", id: :serial, force: :cascade do |t|
    t.text "user_id"
    t.text "toot_id"
    t.timestamptz "created_at"
    t.text "in_reply_to_id"
    t.text "in_reply_to_account_id"
    t.boolean "sensitive"
    t.text "spoiler_text"
    t.text "visibility"
    t.text "language"
    t.text "uri"
    t.text "url"
    t.integer "replies_count"
    t.integer "reblogs_count"
    t.integer "favourites_count"
    t.text "content"
    t.text "reblog"
    t.text "application"
    t.text "account"
    t.text "media_attachments"
    t.text "mentions"
    t.text "tags"
    t.text "emojis"
    t.text "card"
    t.text "poll"
    t.timestamptz "scraped_at"
    t.timestamptz "checked_at"
    t.timestamptz "edited_at"
    t.index ["user_id", "toot_id"], name: "mastodon_toots_user_id_toot_id_idx", unique: true
  end

  create_table "pixiv_members", id: :serial, force: :cascade do |t|
    t.text "username"
    t.text "pixiv_id"

    t.unique_constraint ["pixiv_id"], name: "pixiv_members_pixiv_id_key"
  end

  create_table "pixiv_posts", id: :serial, force: :cascade do |t|
    t.text "pixiv_member_id"
    t.text "post_id"
    t.boolean "parsed"
    t.text "html_dump"
    t.text "title"
    t.integer "page_count"
    t.text "json"
    t.integer "scraped_page_count"
    t.text "pages"
    t.timestamptz "created_at"
    t.text "filenames"
    t.index ["created_at"], name: "pixiv_posts_created_at_idx"
    t.unique_constraint ["post_id"], name: "pixiv_posts_post_id_key"
  end

  create_table "reddit_accounts", id: :serial, force: :cascade do |t|
    t.text "username"
    t.text "uid"
    t.boolean "broken"
    t.boolean "enabled"
    t.timestamptz "last_scraped_at"
    t.text "full_name"
  end

  create_table "reddit_comments", id: :serial, force: :cascade do |t|
    t.text "reddit_id"
    t.text "author"
    t.text "body"
    t.text "link_permalink"
    t.integer "created_utc"
    t.text "subreddit_name_prefixed"
    t.text "link_url"
    t.text "link_title"
    t.text "json"
    t.index ["created_utc"], name: "reddit_comments_created_utc_idx"
  end

  create_table "service_name_path_caches", id: :integer, default: -> { "nextval('service_name_path_cache_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "service"
    t.text "name"
    t.text "username"
    t.timestamptz "updated_at"
    t.text "uid"
  end

  create_table "social_link_contacts", id: :integer, default: -> { "nextval('timeline_contacts_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "uid"
    t.integer "last_atime", default: 0
    t.integer "last_updated"
    t.integer "facebook_last_scraped"
    t.integer "facebook_last_parsed"
    t.integer "facebook_scraper_lock"
    t.integer "last_notification_activity", default: 0
    t.text "activity_cache"
    t.integer "notification_delay", default: 0
    t.boolean "youtube_auto_download"
    t.text "default_filters"
    t.text "query_cache"
  end

  create_table "tumblr_accounts", id: :serial, force: :cascade do |t|
    t.text "full_name"
    t.text "username"
    t.text "uid"
    t.boolean "broken"
    t.boolean "enabled"
    t.timestamptz "last_scraped_at"
  end

  create_table "tumblr_posts", id: :serial, force: :cascade do |t|
    t.text "username"
    t.text "post_id"
    t.boolean "parsed", default: false
    t.text "post_type"
    t.text "amp_html"
    t.text "xml_dump"
    t.timestamptz "timestamp"
    t.index ["post_id"], name: "tumblr_posts_post_id_idx"
    t.index ["timestamp"], name: "tumblr_posts_timestamp_idx"
    t.index ["username"], name: "tumblr_posts_username_idx"
    t.unique_constraint ["post_id"], name: "tumblr_posts_post_id_key"
  end

  create_table "twitter_accounts", id: :serial, force: :cascade do |t|
    t.text "full_name"
    t.text "username"
    t.text "uid"
    t.text "user_id"
    t.boolean "broken"
    t.boolean "enabled", default: true
    t.timestamptz "last_full_scraped_at"
    t.timestamptz "last_partial_scraped_at"
  end

  create_table "twitter_tweets", id: :integer, default: -> { "nextval('tweets_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "user_id", null: false
    t.text "tweet_id", null: false
    t.boolean "is_retweet", null: false
    t.timestamptz "time", null: false
    t.text "text", null: false
    t.integer "replies", null: false
    t.integer "retweets", null: false
    t.integer "likes", null: false
    t.text "entries", null: false
    t.text "original_poster"
    t.timestamptz "scraped_at"
    t.boolean "is_quoting"
    t.boolean "is_reply"
    t.text "reply_data"
    t.text "retweet_data"
    t.text "quoting_data"
    t.timestamptz "checked_at"
    t.boolean "assets"
    t.index ["time"], name: "twitter_tweets_time_idx"
    t.index ["tweet_id"], name: "tweets_tweet_id_idx"
    t.index ["user_id", "tweet_id"], name: "tweets_user_id_tweet_id_idx", unique: true
  end

  create_table "webcomics", id: :serial, force: :cascade do |t|
    t.text "comic"
    t.integer "strip"
    t.text "payload"
    t.date "date"
    t.boolean "parsed", default: false
    t.text "filename"
    t.index ["comic", "strip"], name: "webcomics_comic_strip_idx", unique: true
    t.index ["date"], name: "webcomics_date_idx"
  end

  create_table "youtube_videos", id: :serial, force: :cascade do |t|
    t.text "channel_id"
    t.text "video_id"
    t.text "title"
    t.timestamptz "published_at"
    t.text "item"
    t.boolean "saved"
    t.text "filename"
    t.text "error"
    t.boolean "is_short"
    t.index ["published_at"], name: "youtube_videos_published_at_idx"
    t.index ["video_id"], name: "youtube_videos_video_id_idx", unique: true
  end
end
