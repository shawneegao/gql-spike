module TargetAnnotation
  def annotate_field(type,  null: false, definition:)
    targetClass = self

    targetClass.gql_field_annotations[definition] = {
      type: type,
      null: null
    }

    if instance_methods(false).include?(definition) # if no definition passed in, we're assuming the field can be fetched with target_data#field-name
      orig_method = instance_method(definition) # eh - may rename orig method
      define_method(definition) do
        orig_method.bind(self).call
      end
    end
  end
end