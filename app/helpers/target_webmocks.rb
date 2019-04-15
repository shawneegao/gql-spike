require 'webmock'
include WebMock::API

module TargetWebmocks
  WebMock.enable!
  BASE_URL = 'http://api.resources.com'
  
  def stub_target_data(
    resource:,
    id:,
    response_body:
  )
    stub_request(:get, "http://api.resources.com/#{resource}/#{id}")
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      )
      .to_return(status: 200, body: response_body.to_json, headers: {})
  end
end
