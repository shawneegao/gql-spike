#Boiler plate we are going to 
class Types::PaymentType < Types::BaseObject
    field :id, ID, null: false # this has to be an id for conventions
    field :amount, Int, null: false
    field :merchant, Types::MerchantType, null: false
end