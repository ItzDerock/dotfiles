#!/usr/bin/env bash

# MODEL=$(zenity --list \
#     --title="Background Remover" \
#     --text="Choose processing speed:" \
#     --column="Speed" \
#     --column="Model" \
#     --hide-column=2 \
#     --print-column=2 \
#     "Fast (Lightweight)" "u2netp" \
#     "Slow (High Quality)" "u2net")
# 
# if [ -z "$MODEL" ]; then
#     exit 0
# fi

MODEL=u2net

INPUT_FILE=$(mktemp /tmp/clip_in_XXXXXX.png)
OUTPUT_FILE=$(mktemp /tmp/clip_out_XXXXXX.png)

if wl-paste --list-types | grep -qE "image/png|image/jpeg|image/tiff"; then
    wl-paste -t image/png > "$INPUT_FILE"
else
    notify-send "BG Remover" "Clipboard does not contain a valid image." -u critical
    exit 1
fi

notify-send "BG Remover" "Processing image with $MODEL model... please wait."

if rembg i -m "$MODEL" "$INPUT_FILE" "$OUTPUT_FILE" 2>/tmp/rembg_error.log; then
    wl-copy -t image/png < "$OUTPUT_FILE"
    notify-send "BG Remover" "Success! Background removed."
else
    ERROR_MSG=$(cat /tmp/rembg_error.log)
    notify-send "BG Remover" "Error: $ERROR_MSG" -u critical
fi

rm "$INPUT_FILE" "$OUTPUT_FILE" /tmp/rembg_error.log 2>/dev/null
