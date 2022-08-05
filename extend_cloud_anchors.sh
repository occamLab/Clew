#!/bin/bash


BEARER_TOKEN=`(oauth2l fetch --json ~/Downloads/clew-sandbox-22342ab55d3e.json arcore.management arcore.management)`
curl -H "Authorization: Bearer $BEARER_TOKEN" \
   "https://arcorecloudanchor.googleapis.com/v1beta2/management/anchors?page_size=50&order_by=last_localize_time%20desc" > tokens.json
python3 extend_tokens.py tokens.json $BEARER_TOKEN
