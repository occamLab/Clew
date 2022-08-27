#!/bin/bash


BEARER_TOKEN=`(oauth2l fetch --json ~/Downloads/clew-sandbox-22342ab55d3e.json arcore.management arcore.management)`

if [ $# -eq 0 ]
  then
    curl -H "Authorization: Bearer $BEARER_TOKEN" \
	  "https://arcorecloudanchor.googleapis.com/v1beta2/management/anchors?page_size=100&order_by=expire_time%20asc" > tokens.json
else
    curl -H "Authorization: Bearer $BEARER_TOKEN" \
	  "https://arcorecloudanchor.googleapis.com/v1beta2/management/anchors?page_size=100&order_by=expire_time%20asc&pageToken=$1" > tokens.json
fi
python3 extend_tokens.py tokens.json $BEARER_TOKEN
