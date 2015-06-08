class Machine
  include Mongoid::Document

  field :last_heartbeat, type: DateTime
  field :ip, type: String
  field :cpupercent, type: Float
  field :memtotal, type: Float
  field :memavailable, type: Float
  field :mempercent, type: Float
end
