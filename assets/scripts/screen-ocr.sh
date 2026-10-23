umask 077
TEMP_DIR=$(mktemp -d "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/screen-ocr.XXXXXX")
trap 'rm -rf -- "$TEMP_DIR"' EXIT

if grimblast save area "$TEMP_DIR/region.png"; then
  :
else
  status=$?
  # Grimblast exits with 1 when the region selection is cancelled.
  if [[ $status -eq 1 ]]; then
    exit 0
  fi
  notify-send -a "Screen OCR" -u critical "Screen OCR failed" "Could not capture the selected region."
  exit "$status"
fi

if ! text=$(screen-ocr-recognize "$TEMP_DIR/region.png"); then
  notify-send -a "Screen OCR" -u critical "Screen OCR failed" "Could not recognize text in the selected region."
  exit 1
fi

if [[ ! $text =~ [^[:space:]] ]]; then
  notify-send -a "Screen OCR" "No text found" "Clipboard unchanged. Try selecting a tighter region."
  exit 0
fi

if ! printf '%s' "$text" | wl-copy --type text/plain; then
  notify-send -a "Screen OCR" -u critical "Screen OCR failed" "Could not copy the recognized text."
  exit 1
fi

notify-send -a "Screen OCR" "Text copied" "Recognized text is ready to paste."
