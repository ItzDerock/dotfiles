{ ... }: {
  # runs weekly, randomized by 45 mins
  # deletes gens older than 30 days
  # replaced with nh
  # nix.gc = {
  #   automatic = true;
  #   persistent = true;
  #   dates = "weekly";
  #   randomizedDelaySec = "45min";
  #   options = "--delete-older-than 30d";
  # };

  # Keep, at max, 5 Linux kernels to avoid /boot from filling up
  boot.loader.systemd-boot.configurationLimit = 5;
}
