#!/bin/sh

curl --location -g 'https://camisadimona.com.br/api/v2/shipping' \
	--header "api-key: ${DIMONA_API_KEY}" \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json' \
	--data '{
    "zipcode": "01257-040",
    "quantity": "1"
}'
