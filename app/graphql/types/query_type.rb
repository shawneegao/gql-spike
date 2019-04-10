module Types
  class QueryType < Types::BaseObject
    target_classes = Target.all_target_classes
    root_types_target_classes = [Payment, Merchant]
    
    gql_type_generator = GqlTypeGenerator.new(target_classes)

    gql_type_generator
      .target_to_gql_class_mapping.each do |target_class, gql_type_class|
      GqlTypeGenerator.add_annotated_target_fields_to_gql_type_class(
        target_class, gql_type_class
       )
     end
     
    root_types_target_classes.each do |target_class, gql_type_class|
      gql_type_class =  gql_type_generator.target_to_gql_class_mapping[target_class]
      field_name = target_class.to_s.downcase.to_sym
      field field_name, gql_type_class, null: false do
        argument :id, ID, required: true
      end

      define_method(field_name) do |params|
        targetClass = Object.const_get(field_name.capitalize)
        targetClass.lookup(params[:id])
      end
    end
  end
end
    #  gql_type_generator
    #    .target_to_gql_class_mapping.each do |target_class, gql_type_class|
    #    field_name = target_class.to_s.downcase.to_sym
    #    field field_name, gql_type_class, null: false do
    #      argument :id, ID, required: true
    #    end
 
    #    define_method(field_name) do |params|
    #      targetClass = Object.const_get(field_name.capitalize)
    #      targetClass.lookup(params[:id])
    #    end
    #  end
#    end
#  end