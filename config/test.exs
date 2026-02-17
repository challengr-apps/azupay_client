import Config

config :azupay,
  environments: [
    uat: [
      base_url: "http://localhost:4502/v1",
      api_key: "test_api_key",
      client_id: "test_client_id"
    ],
    prod: [
      base_url: "http://localhost:4502/v1",
      api_key: "test_prod_api_key",
      client_id: "test_prod_client_id"
    ]
  ]
