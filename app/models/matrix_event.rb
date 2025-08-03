class MatrixEvent < ActiveRecord::Base
  establish_connection :hindsight
  belongs_to :room, :primary_key => 'room_id', :class_name => "MatrixRoom"

  attr_accessor :offset

  # SocialLink/Hindsight either need all media on Matrix scraped locally, or they need
  # keys to be able to generate media URLs on demand. If you run a homeserver,
  # this saves the need to download everything. Normal matrix users that don't
  # run their own homeserver shouldn't use this. This also requires you to run a
  # bridge with the mediaProxy component, which is standard on most bridges. Any of
  # them will work just fine.
  def get_media_token
    version = 1
    enddt = -1.0
    mxc = JSON.parse(self.content)["url"].split('mxc://')[1]

    message = [enddt].pack("G") + mxc.encode("UTF-8")

    keydata = Rails.application.credentials.matrix_media_server_signing_key
    key = Base64.urlsafe_decode64(keydata + '=')
    signature = OpenSSL::HMAC.digest("SHA512", key, message)

    token = [version].pack("C") + signature + message
    return Base64.urlsafe_encode64(token).gsub("=", "")
  end

  def timestamp
    return Time.at((self.origin_server_ts + (self.offset || 0)) / 1000.to_f)
  end
end
