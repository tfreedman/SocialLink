class AndroidMms < ActiveRecord::Base
  establish_connection :hindsight
  self.table_name = 'android_mmses'
end
