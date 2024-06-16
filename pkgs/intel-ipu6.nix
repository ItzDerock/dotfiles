
{ stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation rec {
  pname = "intel-ipu6";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu6-drivers";
    rev = "404740a2ff102cf3f5e0ac56de07503048fc5742";  # Use the appropriate tag or commit hash
    sha256 = "sha256-7Teg0ZwzK9fb79OVOpEp5HYPhgyA3FFQOoDgD/egsAw=";  # Replace with the actual sha256
  };

  sourceRoot = "source/";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildInputs = [ kmod ];

  makeFlags = [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  preBuild = ''
    if [[ "${kernel.version}" < "6.8" ]]; then
      cd ${sourceRoot}
      git clone https://github.com/intel/ivsc-driver.git
      cp -r ivsc-driver/backport-include ivsc-driver/drivers ivsc-driver/include .
      rm -rf ivsc-driver
    else
      patch -p1 < ./patch/v6.8/0004-ACPI-scan-Defer-enumeration-of-devices-with-a-_DEP-p.patch
      patch -p1 < ./patch/v6.8/0005-mei-vsc-Unregister-interrupt-handler-for-system-susp.patch
    fi
  '';

  buildPhase = ''
    make -j$(nproc) KERNELRELEASE=${kernel.modDirVersion} KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
  '';

  installPhase = ''
    make KERNELRELEASE=${kernel.modDirVersion} KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build INSTALL_MOD_PATH=$out modules_install
    sudo depmod -a
  '';

  meta = with lib; {
    description = "Intel IPU6 kernel module for kernel versions >= 6.8 and <= 6.6";
    homepage = "https://github.com/intel/ipu6-drivers";
    license = licenses.gpl2;
    maintainers = [ maintainers.yourself ];
    platforms = platforms.linux;
  };
}

