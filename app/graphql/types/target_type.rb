#Boiler plate we are going to 
module Types::TargetType
  include Types::BaseInterface
  
    field :id, ID, null: false,
      description: <<~DOC
        The Target token. GQL clients standardize on the `id` field for identifiers.
        We will refer to tokens as ids in the GQL schema
      DOC

    def id
      object.token
    end

    field :display_name, String, null: false
end