class Device < ActiveRecord::Base
  establish_connection :iot
  serialize :state
  serialize :resource
end
