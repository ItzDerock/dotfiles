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
    rev = "02f619a167d45a569d2150af4f84e06b86b79764";
    hash = "sha256-uIjRyC2wu/Jg5UamO9pYIcNgS0NUWwu/osAFrd80ZhU=";
    # branch = "feat/dot-desktop-from-xdg";
  };

  cargoHash = "sha256-rpOyZlB1FVKLdekCzltOM9h4qMeUoKxvBtvawuz+teg=";

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
