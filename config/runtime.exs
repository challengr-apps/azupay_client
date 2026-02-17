import Config

if config_env() == :prod do
  config :azupay,
    environments: [
      prod: [
        base_url: "https://api.azupay.com.au/v1",
        api_key: System.get_env("AZUPAY_API_KEY"),
        client_id: System.get_env("AZUPAY_CLIENT_ID")
      ]
    ]
end
