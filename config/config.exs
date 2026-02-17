import Config

# Configure the AzuPay API client
#
# config :azupay,
#   environments: [
#     uat: [
#       base_url: "https://api-uat.azupay.com.au/v1",
#       api_key: "your_uat_api_key",
#       client_id: "your_uat_client_id"
#     ],
#     prod: [
#       base_url: "https://api.azupay.com.au/v1",
#       api_key: "your_prod_api_key",
#       client_id: "your_prod_client_id"
#     ]
#   ]

config :azupay,
  environments: [
    uat: [
      base_url: "https://api-uat.azupay.com.au/v1",
      api_key: System.get_env("AZUPAY_UAT_API_KEY"),
      client_id: System.get_env("AZUPAY_UAT_CLIENT_ID")
    ]
  ]

import_config "#{config_env()}.exs"
