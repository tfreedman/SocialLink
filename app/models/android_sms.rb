class AndroidSms < ActiveRecord::Base
  establish_connection :hindsight
  self.table_name = 'android_smses'
end
