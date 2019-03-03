#Boiler plate we are going to 
class Types::Target::PaymentType < Types::BaseObject
  implements Types::TargetType
    field :id, ID, null: false # this has to be an id for conventions
    field :amount, Int, null: false
    field :merchant, Types::Target::MerchantType, null: false
end