class MatrixRoom < ActiveRecord::Base
  serialize :participants
  establish_connection :hindsight
end
