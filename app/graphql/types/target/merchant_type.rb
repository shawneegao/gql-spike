#Boiler plate we are going to 
class Types::Target::MerchantType < Types::BaseObject
  implements Types::TargetType
    field :id, ID, null: false # this has to be an id for conventions
    field :storeName, String, null: false
end