#!/bin/sh

curl --location -g 'https://camisadimona.com.br/api/v2/order/999-320-404' \
	--header "api-key: ${DIMONA_API_KEY}" \
	--header 'Accept: application/json' \
	--header 'Content-Type: application/json'
