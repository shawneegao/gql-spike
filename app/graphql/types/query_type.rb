module Types
  # extend Target

  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # this class method creates a 'field' instance from a list of arguments, keyword arguments, and a block

    # Valid root types can be explicitly declared 
    # or we can just lookup the constants in the Types module
    # make target.rb with mapping
    VALID_ROOT_TYPES = [:Payment, :Merchant]
  
    for type in VALID_ROOT_TYPES do
      targetClass = Module::Target.class_from_sym(type) # obv raise if not valid
      targetFields = targetClass.class_variables #symbols :token, :amount

      gqlTypeClassName = "#{type.to_s}Type"
      
      # replaces merchant_type.rb
      Types.const_set(gqlTypeClassName, Class.new(Types::BaseObject) do
        implements Types::TargetType

        for targetField in targetFields do
          fieldType = targetClass.class_variable_get(targetField.to_sym).type
          nullable = targetClass.class_variable_get(targetField.to_sym).null
          field targetField.to_s.tr("@@", "").to_sym, fieldType, null: nullable
        end
      end)
      

        # we pass in false so that we don't get the instance methods of the super class
        # will probably have to refine this to the ones that are annotated

      # ROOT QUERIES
      fieldName = type.downcase
      gqlTypeClass = "Types::#{gqlTypeClassName}".constantize
      field fieldName, gqlTypeClass, null: false do
        argument :id, ID, required: true
      end
    end

    # Old code that we metaprogrammed away! 

    # field :payment, Types::PaymentType, null: false do

    #   argument :id, ID, required: true
    # end

    # def payment(params)
    #   Payment.lookup(params[:id])
    # end

    # def payment(params)
    #   testLookup :payment, params
    # end

    def self.define_field(fieldName)
      define_method(fieldName) do |params|
        targetClass = Object.const_get(fieldName.capitalize)
        targetClass.lookup(params[:id])
      end
    end

    define_field :payment
    define_field :merchant


    # The next step: 
    # define_method :some_method do |params|
    #   if yield ? yield : 'no custom block! going to default field lookup!'
    #     Payment.lookup(params[:id])
    #   #check if there is a block, if there is a block, then run that
    #   # other wise do a target lookup by id
    # end

    # Comments in my head:
    # use block_given? to check for custom lookup 

    # Have some more sophisticated const checks
    # def class_from_string(str)
    #   str.split('::').inject(Object) do |mod, class_name|
    #     mod.const_get(class_name)
    #   end
    # end

    #lol why is Object.const_defined?(Payment.to_s) true
    # Object.const_defined?("Payment") false?
  end
end
