class WindowsPhoneSms < ActiveRecord::Base
  establish_connection :hindsight
  self.table_name = 'windows_phone_smses'
end
