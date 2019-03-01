module FakeMovieFacts
    class Application < Sinatra::Base
      get "/merchant/:token" do
        {
          merchant: [
            {
              token: "he",
              storeName: "Sobey"
            }
          ]
        }.to_json
      end
    end
  end