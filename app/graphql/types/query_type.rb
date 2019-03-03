module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    #we have to define the fields on here maybe bc unlike targets we don't have a 
    #list of fields that should be here

    #i guess we can store an array of acceptable fields and go with that.

    # this class method creates a field instance from a list of arguments, keyword arguments, and a block

    VALID_ROOT_TYPES = [Types::PaymentType, Types::MerchantType]

    for type in VALID_ROOT_TYPES do
      # use introspection lookup gql type - error if none 
      # get the constant! 
      #unless Types.const_defined?(type) raise "Type #{type} is not not a valid entry point into the schema"

      fieldName = /Types::(.*?)Type/.match(type.to_s)[1].downcase
      field fieldName, type, null: false do
        argument :id, ID, required: true
      end
    end

    # this is what we want to metaprogram away 
    # field :payment, Types::PaymentType, null: false do
    #   binding.pry
    #   argument :id, ID, required: true
    # end

    # demo how this is not working but graphiql shows you example how
    # gql ruby works and its process 
    # this is an instance method

    def payment(params)
      Payment.lookup(params[:id])
    end

    
  end
end
