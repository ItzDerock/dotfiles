#!/usr/bin/env bash

# to set up,
# run `secret-tool store --label "Zipline API key" uploader zipline`
# and `secret-tool store --label "Chibisafe API key" uploader chibisafe`
# to store your API keys.

# CONSTANTS
ZIPLINE_URL="https://media.derock.dev/api/upload"
CHIBISAFE_URL="https://files.derock.media/api/upload"

# run then prompt
kooha

LATEST_SAVED_VIDEO=$(ls -Art ~/Videos/Kooha/ | tail -n 1)

RETURN_VALUE=$(notify-send \
  --action="nothing=Do not upload" \
  --action="zipline=Zipline" \
  --action="chibi=Chibisafe" \
  --action="show=Show" \
  "Upload Video" "Select upload target for $LATEST_SAVED_VIDEO")

FULL_PATH=$(realpath ~/Videos/Kooha/$LATEST_SAVED_VIDEO)
FILE_MIME=$(file --mime-type -b "$FULL_PATH")

echo "File mime: $FILE_MIME"

case $RETURN_VALUE in 
  "nothing")
    echo Doing nothing
    ;;
  "zipline")
    echo Uploading to zipline...
    # retrieve zipline api key
    API_KEY=$(secret-tool lookup uploader zipline)

    OUTPUT=$(curl -H "authorization: $API_KEY" \
      $ZIPLINE_URL \
      -F "file=@$FULL_PATH;type=$FILE_MIME" \
      -H "Content-Type: multipart/form-data");

    echo $OUTPUT

    URL=$(echo $OUTPUT | jq -r '.files[0]' | tr -d '\n')

    wl-copy $URL
    notify-send "Upload Successful" "Uploaded to zipline at $URL"
    ;;
  "chibi")
    echo Uploading to Chibisafe...
    API_KEY=$(secret-tool lookup uploader chibisafe)

    URL=$(curl -H "x-api-key: $API_KEY" \
      -X POST \
      -F "file=@$FULL_PATH;type=$FILE_MIME" \
      $CHIBISAFE_URL | jq -r '.url' | tr -d '\n');

    wl-copy $URL
    notify-send "Upload Successful" "Uploaded to chibisafe at $URL"

    ;;
  "show")
    echo Copying
    thunar $FULL_PATH & disown
  ;;
esac
