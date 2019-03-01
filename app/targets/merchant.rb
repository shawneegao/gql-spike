# frozen_string_literal: true

require 'httparty'
require 'webmock'
include WebMock::API

class Merchant < TargetBase
  associated_target ::Target::BankAccount, :bank_account
  # proto wrappable - do it
  # we can use Target.type_of(object)
  # [Example] Target.type_of(user) ==> ::Target::CAPITAL_CUSTOMER
  # there is also a type is

  def self.target_data_class
    # in real life something more interesting i.e.
    # Squareup::Merchant
    Hash
  end

  # lol there is def a better place to put this
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

  def self.lookup(token)
    @target_data ||= HTTParty.get(BASE_URL + "/merchant/#{token}", format: :json).parsed_response.first
  end

  # figure out how to make this work......
  def token
    token
  end

  def storeName
    target_data.storeName
  end
end
