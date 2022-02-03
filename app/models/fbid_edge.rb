class FBIDEdge < ActiveRecord::Base
  establish_connection :development

  belongs_to :from_fbid, :foreign_key => "from", :class_name => "FBID"
  belongs_to :to_fbid, :foreign_key => "to", :class_name => "FBID"
end
