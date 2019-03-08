require 'httparty'
require 'webmock'
include WebMock::API

class Payment < TargetBase
  associated_target Merchant, :merchant

  def self.target_data_class
    # in real life something more interesting i.e.
    # Squareup::Merchant
    Hash
  end

  def self._fetch_target_data(token)
    raw_data = HTTParty.get(BASE_URL + "/payment/#{token}", format: :json).parsed_response.first
    OpenStruct.new(raw_data)
  end

  def self.target_data_class
    OpenStruct
  end

  # annotation is going to turn these instance methods into instance variables 
  # which will be objects that we can then in our query type call
  # field.type, field.null? etc. 
  annotate_field "Integer", null: false, definition: 
    def amount
      target_data.amount
    end
  
  annotate_field "Types::BaseObject::ID", null: false, definition: 
    def token
      target_data.token
    end

  # not annotated bc this field does not need to exposed to the 
  # graphQL type
  def merchant_token
    target_data.merchant_token
  end

  annotate_field "Types::MerchantType", null: false, definition: 
    def merchant
      @merchant ||= Merchant.lookup(merchant_token)
    end

  ###################
  # Webmock
  ###################
  WebMock.enable!
  BASE_URL = 'http://api.resources.com'

  # need to figure out how to stub regex
  stub_request(:get, 'http://api.resources.com/payment/1234')
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent' => 'Ruby'
      }
    )
    .to_return(status: 200, body: [{
      token: '1234',
      amount: 120,
      merchant_token: 'adfadf'
    }].to_json, headers: {})
  

  # proto wrappable - do it
  # we can use Target.type_of(object)
  # [Example] Target.type_of(user) ==> ::Target::CAPITAL_CUSTOMER
  # there is also a type is
end
