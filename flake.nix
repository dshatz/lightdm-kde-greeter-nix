{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs}:

    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
    {
      overlay = final: prev: {

        kde-greeter = with final; stdenv.mkDerivation {
          pname = "kde-greeter";
          name = "kde-greeter";

          src = pkgs.fetchurl {
            url = "https://invent.kde.org/golubevan/lightdm-kde-greeter/-/archive/ups-port-kde6/lightdm-kde-greeter-ups-port-kde6.tar.gz";
            hash = "sha256-AHmyCYRxwK6K3eYjJxuHIL+uOK4EiWTIf30K9Lo3f5s=";
          };
          nativeBuildInputs = [ cmake kdePackages.extra-cmake-modules kdePackages.qtbase qt6.full kdePackages.wrapQtAppsHook pkg-config lightdm gtk2 kdePackages.networkmanager-qt kdePackages.kiconthemes kdePackages.kcmutils kdePackages.kpackage kdePackages.plasma-workspace];
          dontWrapQtApps = true;
          cmakeFlags = [
            "-DGREETER_IMAGES_DIR=images"
            "-DBUILD_TESTING=ON"
            "-DCMAKE_BUILD_TYPE=Debug"
            "-DCMAKE_INSTALL_PREFIX='./builds/plasma/lightdm-kde-greeter/_install'"
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
            "-DECM_ENABLE_SANITIZERS='address'"
            "-DGREETER_DEFAULT_WALLPAPER=default.jpg"
            "-DBUILD_WITH_QT6=ON"
            "-DQT_MAJOR_VERSION=6"
            "-DLIGHTDM_CONFIG_DIR=./_install"
            "-DDATA_INSTALL_DIR=./install_data"
          ];


        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) kde-greeter;
      });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.kde-greeter);





#     packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
#     packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
