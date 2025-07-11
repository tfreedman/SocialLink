class VoipmsSms < ActiveRecord::Base
  self.table_name = 'voipms_smses'
  establish_connection :hindsight
end
