{ stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "samsung-galaxybook-extras-${version}-${kernel.version}";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "itzderock";
    repo = "samsung-galaxybook-extras";
    rev = "feab69614ad0ce7d605ef83af77328bec407afab";
    sha256 = "sha256-GVSIIZaPLs3PCjsmNlqN4fVSseX1VypgtdXPg+dr33I=";
  };

  # sourceRoot = "source/driver";
  hardeningDisable = [ "pic" "format" ];                                             # 1
  nativeBuildInputs = kernel.moduleBuildDependencies;                       # 2

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"                                 # 3
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"    # 4
    "INSTALL_MOD_PATH=$(out)"                                               # 5
  ];

  installPhase = ''
    make SHELL=${stdenv.shell} KERNELRELEASE=${kernel.modDirVersion} KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build INSTALL_MOD_PATH=$out modules_install
  '';

  meta = with lib; {
    description = "Mimics Samsung System Event Controller, allowing for more configuration.";
    homepage = "https://github.com/joshuagrisham/samsung-galaxybook-extras";
    license = licenses.gpl2;
    maintainers = [ maintainers.derock ];
    platforms = platforms.linux;
  };
}
