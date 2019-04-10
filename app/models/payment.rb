require 'httparty'
include TargetWebmocks

class Payment < TargetBase
  mattr_accessor :gql_field_annotations do
    {}
  end

  stub_target_data(
    resource: 'payment',
    id: 1234,
    response_body: {
      id: 1234,
      amount: 100,
      merchant_id: 4567,
      card_id: 7890
    }
  )

  def self._fetch_target_data(id)
    # IRL: LedgerClient.get_payment(id)

    raw_data = HTTParty.get(BASE_URL + "/payment/#{id}", format: :json)
      .parsed_response
    OpenStruct.new(raw_data)
  end

  annotate_field "Integer", null: false, definition: 
    def amount
      target_data.amount
    end
  
  annotate_field "Types::BaseObject::ID", null: false, definition: 
    def id
      target_data.id
    end

  def card_id
    target_data.card_id
  end
  
  annotate_field "Types::CardType", null: false, definition: 
    def card
      @card ||= Card.lookup(card_id)
    end

  def merchant_id
    target_data.merchant_id
  end

  annotate_field "Types::MerchantType", null: false, definition: 
    def merchant
      @merchant ||= Merchant.lookup(merchant_id)
    end
end
