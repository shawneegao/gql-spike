require 'httparty'
include TargetWebmocks

class Merchant < TargetBase
  mattr_accessor :gql_field_annotations do
    {}
  end
  
  stub_target_data(
    resource: 'merchant',
    id: 4567,
    response_body: {
      id: 4567,
      store_name: 'Grillz by Nelly'
    }
  )

  def self._fetch_target_data(id)
    raw_data = HTTParty.get(BASE_URL + "/merchant/#{id}", format: :json).parsed_response
    OpenStruct.new(raw_data)
  end

  annotate_field "Types::BaseObject::ID", null: false, definition: 
    def id
      target_data.id
    end
    
  annotate_field "String", null: false, definition: 
    def store_name
      target_data.store_name
    end
end
