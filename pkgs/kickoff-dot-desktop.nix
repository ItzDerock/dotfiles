{ lib
, fetchFromGitHub
, rustPlatform
, fontconfig
, pkg-config
, wayland
, libxkbcommon
, makeWrapper
}:
rustPlatform.buildRustPackage rec {
  pname = "kickoff-dot-desktop";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "j0ru";
    repo = pname;
    rev = "ba3e8788c7120c95c4ee963abf3904eb0736cb24";
    hash = "sha256-exMmqOkDKuyAEdda8gG/uF3+tnQzhJnOJK+sEtZbsZc=";
    # branch = "feat/dot-desktop-from-xdg";
  };

  cargoHash = "sha256-sLztMbfabVz1AXZ08waDrIWpG8CkdKe8hN99JOCJj6w=";

  libPath = lib.makeLibraryPath [
    wayland
    libxkbcommon
  ];

  buildInputs = [ fontconfig libxkbcommon ];
  nativeBuildInputs = [ makeWrapper pkg-config ];

  postInstall = ''
    wrapProgram "$out/bin/kickoff-dot-desktop" --prefix LD_LIBRARY_PATH : "${libPath}"
  '';

  meta = with lib; {
    description = "Smol program to read in relevant desktop files and print them in a kickoff compatible format";
    homepage = "https://github.com/j0ru/kickoff-dot-desktop";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ derock ];
    platforms = platforms.linux;
  };
}
