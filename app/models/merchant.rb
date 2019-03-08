# frozen_string_literal: true
# fyi target_data is in target_methods
require 'httparty'
require 'webmock'
include WebMock::API

class Merchant < TargetBase
  def self._fetch_target_data(token)
    raw_data = HTTParty.get(BASE_URL + "/merchant/#{token}", format: :json).parsed_response.first
    OpenStruct.new(raw_data)
  end

  def self.target_data_class
    OpenStruct
  end

  annotate_field "Types::BaseObject::ID", null: false, definition:
    def token
      target_data.token
    end
  
  annotate_field "String", null: false, definition:
    def store_name
      target_data.storeName
    end

  ###################
  # Webmock
  ###################
  WebMock.enable!
  BASE_URL = 'http://api.resources.com'

  # need to figure out how to stub regex
  stub_request(:get, 'http://api.resources.com/merchant/adfadf')
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent' => 'Ruby'
      }
    )
    .to_return(status: 200, body: [{
      token: 'adfadf',
      storeName: 'Sobey'
    }].to_json, headers: {})
end
