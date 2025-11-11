#!/usr/bin/env bash

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"

umask 077 # new files are not readable by anyone
TEMP_DIR=$(mktemp -d)
SCREENSHOT_DATE=$(date +"%Y-%m-%d_%H:%M:%S")

# Select region and save + copy
pkill slurp || true
PICTURE_DIM=$(grimblast save -f ${1:-area} $TEMP_DIR/screenshot.png 2>&1 | sed -n 's/.* \([0-9]\+x[0-9]\+\).*/\1/p')

if [ ! -f "$TEMP_DIR/screenshot.png" ]; then
  echo "Screenshot doesn't exist."
  rm -r $TEMP_DIR
  exit 0
fi

wl-copy < $TEMP_DIR/screenshot.png

# if no picture dimensions, use `file` to find as fallback
if [[ -z "$PICTURE_DIM" ]]; then
  echo "warn: Grimblast did not return dimensions!"
  PICTURE_DIM=$(file "$TEMP_DIR/screenshot.png" | cut -d, -f2 | sed "s/ //g")
fi

# Ask user what they want to do
notify-send "Screenshot Taken" \
  "Copied the $PICTURE_DIM image to clipboard. Click for actions." \
  -w \
  -a Screenshots \
  --action="save=Save" \
  --action="edit=Edit" > "$TEMP_DIR/notify.out" &

NOTIFY_PID=$!

# Wait up to 30 seconds for notify-send to end.
SECONDS_WAITED=0
while kill -0 "$NOTIFY_PID" 2>/dev/null; do
  if [ $SECONDS_WAITED -ge 30 ]; then
    echo "Process $NOTIFY_PID timed out after 30 seconds." 
    kill "$NOTIFY_PID"
    break 
  fi
  sleep 1
  SECONDS_WAITED=$((SECONDS_WAITED + 1))
done

# Read from notify.out to see chosen selection
SELECTED_OPTION=$(cat "$TEMP_DIR/notify.out")
echo "Selected $SELECTED_OPTION"

case "$SELECTED_OPTION" in 
  "save")
    mv $TEMP_DIR/screenshot.png $OUTPUT_DIR/$SCREENSHOT_DATE.png
    ;;
  "edit")
    satty --filename $TEMP_DIR/screenshot.png \
      --early-exit \
      --actions-on-enter save-to-clipboard \
      --save-after-copy \
      --copy-command 'wl-copy' \
      --initial-tool brush 
    ;;
  *)
    echo "Fallback case reached. Doing nothing."
    ;;
esac

# cleanup
rm -r $TEMP_DIR
