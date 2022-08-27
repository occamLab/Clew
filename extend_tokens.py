#!/usr/bin/env python3

import json
import sys
import os

def extend_token(auth_token, anchor_id, expire_time):
     curl_cmd = 'BEARER_TOKEN=`(oauth2l fetch --json ~/Downloads/clew-sandbox-22342ab55d3e.json arcore.management arcore.management)`; curl -H "Authorization: Bearer $BEARER_TOKEN" -H "Content-Type: application/json" -X "PATCH" \
   "https://arcorecloudanchor.googleapis.com/v1beta2/management/anchors/' + anchor_id + '?updateMask=expire_time" \
    -d \'{ expireTime: "' + expire_time + '" }\''
     print(os.system(curl_cmd))

if len(sys.argv) < 3:
    print("USAGE: ./extend_tokens.py path-to-tokens.json auth")
    sys.exit(1)

with open(sys.argv[1]) as f:
    data = json.load(f)

for anchor in data['anchors']:
    if anchor['expireTime'] != anchor['maximumExpireTime']:
        extend_token(sys.argv[2], os.path.basename(anchor['name']), anchor['maximumExpireTime'])

if 'nextPageToken' in data:
    os.system('./extend_cloud_anchors.sh ' + data['nextPageToken'])
