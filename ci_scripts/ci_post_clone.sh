#!/bin/bash

brew install wget

wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1HC_b_21A005Lo98Eskn7yAqWefbw4FU9' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1HC_b_21A005Lo98Eskn7yAqWefbw4FU9" -O opencv2.framework.zip && rm -rf /tmp/cookies.txt
unzip opencv2.framework.zip
rm opencv2.framework.zip
mv opencv2.framework ..
