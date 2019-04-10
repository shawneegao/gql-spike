require 'rails_helper'
 
describe "GqlTypeGenerator#initialize" do
  let(:all_target_classes) do
    Target.all_target_classes
  end

  context 'before initializing GqlTypeGenerator' do
    
    all_target_classes.each do |target_class|
      expect{ "Types::#{target_class.to_s}Type".constantize }.to raise_error(NameError)
    end
  end

  gql_type_generator = GqlTypeGenerator.new(all_target_classes)

  all_target_classes.each do |target_class|
    gql_type_class_name = "Types::#{target_class.to_s}Type".constantize
      expect(gql_type_class_name).to be_instance_of Class
      gql_type_generator.target_to_gql_class_mapping[target_class] = gql_type_class_name
    end
  end
end