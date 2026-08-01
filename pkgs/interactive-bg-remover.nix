# Interactive Image Background Remover — packaged locally rather than
# consuming the upstream repo as a flake input, since upstream ships no nix
# expression and there is no fork to maintain. Bump `version`/`rev`/`hash`
# together when a new upstream tag lands.
{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  makeShellWrapper,
  makeDesktopItem,
  copyDesktopItems,
  qt6,
}:

let
  # Runtime deps, mirrors upstream requirements.txt.
  pythonEnv = python3.withPackages (
    ps: with ps; [
      pillow
      scipy
      numpy
      onnx
      onnxruntime
      opencv4 # provides the `cv2` module
      pyqt6
      requests
      pymatting # pulls in numba
    ]
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = "interactive-bg-remover";
  version = "1.8.5";

  src = fetchFromGitHub {
    owner = "pricklygorse";
    repo = "Interactive-Image-Background-Remover";
    rev = "v${finalAttrs.version}";
    hash = "sha256-KYvTDn75Vx79njUrKiN9UMUdZOaBfSZHdZ/6ok28MGw=";
  };

  nativeBuildInputs = [
    # wrapQtAppsHook pulls in makeBinaryWrapper, which has no --run; we need the
    # shell wrapper so the model/cache dirs can be computed at launch time.
    makeShellWrapper
    copyDesktopItems
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
  ];

  # We wrap the python interpreter ourselves below, reusing $qtWrapperArgs.
  dontWrapQtApps = true;
  dontBuild = true;

  postPatch = ''
    # The upstream default model directory is <script dir>/Models, which is
    # read-only inside the nix store. Honour $IBR_MODEL_DIR (set by the wrapper)
    # so runtime model downloads land somewhere writable.
    substituteInPlace backgroundremoval.py \
      --replace-fail \
        'default_model_dir = os.path.join(script_base, "Models")' \
        'default_model_dir = os.environ.get("IBR_MODEL_DIR") or os.path.join(script_base, "Models")'

    # Match the .desktop file id installed below so window managers can
    # associate the running window with its icon.
    substituteInPlace backgroundremoval.py \
      --replace-fail \
        'app.setDesktopFileName("Interactive Background Remover")' \
        'app.setDesktopFileName("interactive-bg-remover")'
  '';

  installPhase = ''
    runHook preInstall

    appdir=$out/share/interactive-bg-remover
    mkdir -p "$appdir"
    cp backgroundremoval.py "$appdir/"
    cp -r src "$appdir/"

    install -Dm644 src/assets/splash.png \
      $out/share/pixmaps/interactive-bg-remover.png

    makeShellWrapper ${pythonEnv}/bin/python $out/bin/interactive-bg-remover \
      --add-flags "$appdir/backgroundremoval.py" \
      --run 'export IBR_MODEL_DIR="''${IBR_MODEL_DIR:-''${XDG_DATA_HOME:-$HOME/.local/share}/interactive-bg-remover/Models}"' \
      --run 'mkdir -p "$IBR_MODEL_DIR"' \
      --run 'export NUMBA_CACHE_DIR="''${NUMBA_CACHE_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/interactive-bg-remover/numba}"' \
      --run 'mkdir -p "$NUMBA_CACHE_DIR"' \
      "''${qtWrapperArgs[@]}"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "interactive-bg-remover";
      desktopName = "Interactive Background Remover";
      comment = "Interactively remove image backgrounds with SAM and matting models";
      exec = "interactive-bg-remover %F";
      icon = "interactive-bg-remover";
      categories = [
        "Graphics"
        "Photography"
      ];
      mimeTypes = [
        "image/png"
        "image/jpeg"
        "image/webp"
        "image/tiff"
        "image/bmp"
      ];
      startupWMClass = "Interactive Background Remover";
    })
  ];

  passthru.pythonEnv = pythonEnv;

  meta = {
    description = "Interactive image background remover (PyQt6 + ONNX Runtime)";
    homepage = "https://github.com/pricklygorse/Interactive-Image-Background-Remover";
    mainProgram = "interactive-bg-remover";
    platforms = lib.platforms.linux;
  };
})
