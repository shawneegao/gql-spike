 class Utils
  attr_accessor :target_to_gql_class_mapping

  def initialize(target_classes)
    @target_to_gql_class_mapping = {}

    target_classes.each do |target_class|
      gql_type_class_name = "#{target_class.to_s}Type" # "PaymentType"

      @target_to_gql_class_mapping[target_class] = 
        Types.const_set( # we set a const on Types, Types::PaymentType 
          gql_type_class_name, # to a class that inherits Types::BaseObject 
          Class.new(Types::BaseObject) do # and implements Types::TargetType
            implements Types::TargetType
          end
        )
    end
  end

  def self.add_annotated_target_fields_to_gql_type_class(target_class, gql_type_class)
      # reopen class and add the fields!
    gql_type_class.class_eval do
      def self.authorized?(object, context)
        super && (context[:current_user].has_street_cred?)
      end
      target_class.gql_field_annotations.each do | field_name, field_definition_hash |
        fieldType = field_definition_hash[:type].constantize
        nullable = field_definition_hash[:null]
        field field_name, fieldType, null: nullable
      end
    end
  end
end