{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.rockcfg.dolphin;

  extractScript = pkgs.writeShellApplication {
    name = "extract-to-subfolder";

    runtimeInputs = with pkgs; [
      libarchive # bsdtar: universal archive extraction
      coreutils # realpath, basename, dirname, mkdir, tr, stat, stdbuf, wc
      libnotify # notify-send
      kdePackages.kdialog # progress dialog
      qt6.qttools # qdbus6: D-Bus dialog control
    ];

    text = ''
      SIZE_THRESHOLD_MB=${toString cfg."extract-shortcut".sizeThresholdMB}
      TIME_THRESHOLD_S=${toString cfg."extract-shortcut".timeThresholdSeconds}

      # validate input
      if [[ $# -lt 1 ]] || [[ -z "$1" ]]; then
        notify-send "Extract to Subfolder" "No file specified."
        exit 1
      fi

      archive="$(realpath -- "$1")"

      if [[ ! -f "$archive" ]]; then
        notify-send "Extract to Subfolder" "Not a file: $1"
        exit 1
      fi

      dir="$(dirname  -- "$archive")"
      filename="$(basename -- "$archive")"

      # derive subfolder name
      # Strip the archive extension(s).
      case "$filename" in
        *.tar.gz|*.tar.bz2|*.tar.xz|*.tar.zst|*.tar.lz|*.tar.lzma|*.tar.Z)
          subfolder="''${filename%%.*}" ;;   # double-extension, strip from first dot
        *)
          subfolder="''${filename%.*}" ;;    # single extension
      esac

      # drop ASCII control characters (0x00-0x1F, 0x7F).
      subfolder="$(printf '%s' "$subfolder" | tr -d '\000-\037\177')"

      # Fallback if the name ended up empty (e.g. ".tar.gz" with no stem).
      if [[ -z "$subfolder" ]]; then
        subfolder="extracted"
      fi

      dest="$dir/$subfolder"

      # avoid clobbering existing paths
      if [[ -e "$dest" ]]; then
        i=2
        while [[ -e "''${dest}_''${i}" ]]; do
          i=$((i + 1))
        done
        dest="''${dest}_''${i}"
      fi

      mkdir -p -- "$dest"

      # --- progress infrastructure ---
      tmplines=$(mktemp)
      tmpcount=$(mktemp)
      dbus_svc=""
      dbus_path=""
      dialog_open_time=0
      last_eta_update=0
      total=0
      use_real_progress=false

      cleanup() {
        rm -f "$tmplines" "$tmpcount"
        if [[ -n "$dbus_svc" ]]; then
          qdbus6 "$dbus_svc" "$dbus_path" close 2>/dev/null || true
        fi
      }
      trap cleanup EXIT

      # start background entry count immediately (zip: instant; tar.*: sequential)
      bsdtar tf "$archive" 2>/dev/null | wc -l > "$tmpcount" &
      count_pid=$!

      # start background extraction; verbose stdout lets us count extracted entries
      stdbuf -oL bsdtar xvf "$archive" -C "$dest" > "$tmplines" 2>/dev/null &
      extract_pid=$!

      # size-based trigger
      filesize_bytes=$(stat -c%s "$archive")
      filesize_mb=$(( filesize_bytes / 1048576 ))
      show_progress=false
      if (( filesize_mb >= SIZE_THRESHOLD_MB )); then
        show_progress=true
      fi

      start_time=$(date +%s)

      open_dialog() {
        # wait up to 1 s for the entry count to arrive
        count_ticks=0
        while kill -0 "$count_pid" 2>/dev/null && (( count_ticks < 10 )); do
          sleep 0.1
          count_ticks=$(( count_ticks + 1 ))
        done
        kill "$count_pid" 2>/dev/null || true
        wait "$count_pid" 2>/dev/null || true

        raw="$(cat "$tmpcount" 2>/dev/null)" || raw=""
        raw="$(printf '%s' "$raw" | tr -d '[:space:]')"
        if [[ "$raw" =~ ^[0-9]+$ ]] && (( raw > 0 )); then
          total=$raw
          use_real_progress=true
        else
          # fallback: fake time-based progress, 5 %/s capped at 95 %
          total=100
          use_real_progress=false
        fi

        dbus_ref="$(kdialog --title "Extract to Subfolder" \
          --progressbar "Extracting ''${filename}..." "$total" 2>/dev/null)" || dbus_ref=""
        dbus_svc="$(awk '{print $1}' <<< "$dbus_ref")"
        dbus_path="$(awk '{print $2}' <<< "$dbus_ref")"
        dialog_open_time=$(date +%s)
        last_eta_update=$dialog_open_time
      }

      # monitor loop (0.1 s intervals)
      while kill -0 "$extract_pid" 2>/dev/null; do
        # time-based trigger
        if [[ "$show_progress" == "false" ]]; then
          elapsed=$(( $(date +%s) - start_time ))
          if (( elapsed >= TIME_THRESHOLD_S )); then
            show_progress=true
          fi
        fi

        # open dialog on first trigger
        if [[ "$show_progress" == "true" ]] && [[ -z "$dbus_svc" ]]; then
          open_dialog
        fi

        # update open dialog
        if [[ -n "$dbus_svc" ]]; then
          if [[ "$use_real_progress" == "true" ]]; then
            current=$(wc -l < "$tmplines" 2>/dev/null || echo 0)
          else
            elapsed_fake=$(( $(date +%s) - dialog_open_time ))
            current=$(( elapsed_fake * 5 ))
            if (( current > 95 )); then current=95; fi
          fi

          qdbus6 "$dbus_svc" "$dbus_path" Set "" value "$current" 2>/dev/null || true

          # update ETA label at most once per second
          now=$(date +%s)
          if [[ "$use_real_progress" == "true" ]] && \
             (( total > 1 && current > 0 && now >= last_eta_update + 1 )); then
            elapsed_since_open=$(( now - dialog_open_time ))
            if (( elapsed_since_open > 0 )); then
              rate=$(( current / elapsed_since_open ))
              if (( rate > 0 )); then
                eta=$(( (total - current) / rate ))
                qdbus6 "$dbus_svc" "$dbus_path" setLabelText \
                  "Extracting ''${filename}... (~''${eta}s remaining)" 2>/dev/null || true
              fi
            fi
            last_eta_update=$now
          fi

          # cancel check
          cancelled="$(qdbus6 "$dbus_svc" "$dbus_path" wasCancelled 2>/dev/null)" || cancelled="false"
          if [[ "$cancelled" == "true" ]]; then
            kill "$extract_pid" 2>/dev/null || true
            wait "$extract_pid" 2>/dev/null || true
            rm -rf -- "$dest" 2>/dev/null || true
            qdbus6 "$dbus_svc" "$dbus_path" close 2>/dev/null || true
            dbus_svc=""
            notify-send "Extract to Subfolder" "Cancelled: $filename"
            exit 1
          fi
        fi

        sleep 0.1
      done

      wait "$extract_pid"
      extract_status=$?

      # set to 100 % and close
      if [[ -n "$dbus_svc" ]]; then
        qdbus6 "$dbus_svc" "$dbus_path" Set "" value "$total" 2>/dev/null || true
        qdbus6 "$dbus_svc" "$dbus_path" close 2>/dev/null || true
        dbus_svc=""
      fi

      if (( extract_status != 0 )); then
        notify-send "Extract to Subfolder" "Extraction failed: $filename"
        rmdir -- "$dest" 2>/dev/null || true
        exit 1
      fi

      # highlight the result in Dolphin
      dolphin --select "$(realpath -- "$dest")" &>/dev/null &
      disown

      notify-send "Extract to Subfolder" "Extracted: $(basename -- "$dest")"
    '';
  };

  serviceMenu = pkgs.writeTextDir "share/kio/servicemenus/extract-to-subfolder.desktop" ''
    [Desktop Entry]
    Type=Service
    MimeType=application/zip;application/x-tar;application/gzip;application/x-bzip2;application/x-xz;application/zstd;application/x-7z-compressed;application/x-rar;application/vnd.rar;application/x-compressed-tar;application/x-bzip-compressed-tar;application/x-xz-compressed-tar;application/x-zstd-compressed-tar;application/x-lz-compressed-tar;application/x-lzma-compressed-tar;application/x-cpio;
    Actions=extractToSubfolder

    [Desktop Action extractToSubfolder]
    Name=Extract to Subfolder
    Icon=archive-extract
    Exec=${extractScript}/bin/extract-to-subfolder "%f"
  '';

in
{
  options.rockcfg.dolphin."extract-shortcut" = {
    enable = lib.mkEnableOption "Dolphin right-click 'Extract to Subfolder' action";
    sizeThresholdMB = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Show progress bar if archive exceeds this many MB.";
    };
    timeThresholdSeconds = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Show progress bar if extraction takes longer than this many seconds.";
    };
  };

  config = lib.mkIf cfg."extract-shortcut".enable {
    environment.systemPackages = [
      extractScript # puts the script in PATH
      serviceMenu # installs the .desktop into $XDG_DATA_DIRS/kio/servicemenus/
    ];
  };
}
