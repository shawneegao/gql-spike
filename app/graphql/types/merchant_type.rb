#Boiler plate we are going to 
class Types::MerchantType < Types::BaseObject
    field :id, ID, null: false # this has to be an id for conventions
    field :storeName, String, null: false
end