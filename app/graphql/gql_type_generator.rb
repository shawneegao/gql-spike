class GqlTypeGenerator
  attr_accessor :target_to_gql_class_mapping

  def initialize(target_classes)
    @target_to_gql_class_mapping = {}

    target_classes.each do |target_class|
      gql_type_class_name = "#{target_class}Type"

      @target_to_gql_class_mapping[target_class] = 
        Types.const_set(
          gql_type_class_name,
          Class.new(Types::BaseObject) do
            implements Types::TargetType
          end
        )
    end
  end

  def self.add_annotated_target_fields_to_gql_type_class(target_class, gql_type_class)
    gql_type_class.class_eval do
      target_class.gql_field_annotations.each do | field_name, field_definition_hash |
        fieldType = field_definition_hash[:type].constantize
        nullable = field_definition_hash[:null]
        field field_name, fieldType, null: nullable
      end
    end
  end
end

