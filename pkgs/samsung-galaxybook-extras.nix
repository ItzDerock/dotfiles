{ stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  name = "samsung-galaxybook-extras-${version}-${kernel.version}";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "itzderock";
    repo = "samsung-galaxybook-extras";
    rev = "b98fd03c4653a5bd7ca4d0c82dd1cf33f5793151";
    sha256 = "sha256-gUNx1jFgLv/SOcOm2TSAfSZrPbysyyQZ/ud1vtrcabU=";
  };

  sourceRoot = "source/driver";
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
