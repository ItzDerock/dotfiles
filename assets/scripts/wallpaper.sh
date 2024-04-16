#!/usr/bin/env sh

wallpaper_dir="$HOME/NixOS/assets/wallpapers"
current_wallpaper="$HOME/.cache/current-wallpaper.png"

# Function to set the wallpaper
set_wallpaper() {
  local image_path="$1"

  if [[ ! -f "$image_path" ]]; then
    echo "Error: File '$image_path' does not exist."
    return 1
  fi
 
  # Set wallpaper using swww
  swww img "$image_path" # --transition-type center
  
  # use pywal to create colors
  # wal -n -i "$image_path" 

  # If is NOT PNG, use imagemagick to convert to PNG
  # This is for hyprlock as it only supports PNGs
  if [[ ! "$(file -b --mime-type "$image_path")" == "image/png" ]]; then
    # Convert to PNG using imagemagick
    convert "$image_path" "$current_wallpaper"
    image_path="$current_wallpaper"
  else 
    # Symlink to current wallpaper (if PNG)
    ln -sf "$image_path" "$current_wallpaper"
  fi
}

# Main script logic
case "$1" in
  select)
    if [[ ! -d "$wallpaper_dir" ]]; then
      echo "Error: Directory '$wallpaper_dir' does not exist."
      exit 1
    fi
    selected_image=$(nsxiv -t -o "$wallpaper_dir"/* 2>/dev/null)
    if [[ -n "$selected_image" ]]; then
      set_wallpaper "$selected_image"
    fi
    ;;
  set)
    if [[ -z "$2" ]]; then
      echo "Error: Please provide an image path."
      exit 1
    fi
    set_wallpaper "$2"
    ;;
  random)
    # Read random file from directory
    random_image=$(find "$wallpaper_dir" -type f -print0 | shuf -zn1 -z)
    if [[ -n "$random_image" ]]; then
      set_wallpaper "$random_image"
      echo "Random wallpaper set: $random_image"
    else
      echo "Error: No files found in '$wallpaper_dir'"
    fi
    ;;
  *)
    echo "Usage: $0 (select|set <image>|random)"
    exit 1
    ;;
esac
