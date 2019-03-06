module TargetAnnotation
  def annotate_field(type,  null: false, definition:) # TODO: add permission
    targetClass = self

    # add simple fields like "public/private/lead level etc"
    # the name of the passed in definition method will be the name of the field
    # may add an option to add custom names later
    targetClass.class_variable_set("@@#{definition}", OpenStruct.new(
      :type => type, #eventuall here we need to use a util to convert it into a pagination type
      :null => null,
    ))

    if instance_methods(false).include?(definition) # if no definition passed in, we're assuming the field can be fetched with target_data#field-name
      orig_method = instance_method(definition) # eh - may rename orig method
      define_method(definition) do
        #check permissions here?
        orig_method.bind(self).call
      end
    end
    
    definition
  end
end