require 'httparty'
include TargetWebmocks

class Card < TargetBase
  mattr_accessor :gql_field_annotations do
    {}
  end

  stub_target_data(
    resource: 'card',
    id: 7890,
    response_body: {
      id: 7890,
      country_code: 'US',
      names_on_card:'Shawnee Gao',
      postal_code: 94114,
      payment_id: 1234
    } 
  )

  def self._fetch_target_data(id)
    raw_data = HTTParty.get(BASE_URL + "/card/#{id}", format: :json)
      .parsed_response
    OpenStruct.new(raw_data)
  end

  annotate_field "String", null: false, definition: 
    def country_code
      target_data.country_code
    end

  annotate_field "String", null: false, definition: 
  def names_on_card
      target_data.names_on_card
  end

  annotate_field "Integer", null: false, definition: 
  def postal_code
      target_data.postal_code
  end

  def payment_id
    target_data.payment_id
  end
  
  annotate_field "Types::PaymentType", null: false, definition: 
    def payment
      @payment ||= Payment.lookup(payment_id)
    end
end
