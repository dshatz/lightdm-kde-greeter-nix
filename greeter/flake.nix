{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs}:

    let
        inherit (nixpkgs.lib) genAttrs optional;
      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

        eachSystem = f: genAttrs
            [
            "aarch64-darwin"
            "aarch64-linux"
            "x86_64-darwin"
            "x86_64-linux"
            ]
            (system: f nixpkgs.legacyPackages.${system});

    lightdm-kde-greeter = { pkgs, ...}: pkgs.stdenv.mkDerivation {
        pname = "lightdm-kde-greeter";
        name = "lightdm-kde-greeter";
        version = "0.1";

        src = pkgs.fetchurl {
        url = "https://invent.kde.org/golubevan/lightdm-kde-greeter/-/archive/ups-port-kde6/lightdm-kde-greeter-ups-port-kde6.tar.gz";
        hash = "sha256-AHmyCYRxwK6K3eYjJxuHIL+uOK4EiWTIf30K9Lo3f5s=";
        };
        nativeBuildInputs = with pkgs; [ cmake kdePackages.extra-cmake-modules kdePackages.qtbase qt6.full kdePackages.wrapQtAppsHook pkg-config lightdm gtk2 kdePackages.networkmanager-qt kdePackages.kiconthemes kdePackages.kcmutils kdePackages.kpackage kdePackages.plasma-workspace kdePackages.qtshadertools];
        dontWrapQtApps = true;
        dontUseCmakeConfigure=true;
        buildPhase = ''
        cmake -DGREETER_IMAGES_DIR=images -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DECM_ENABLE_SANITIZERS='address' -DGREETER_DEFAULT_WALLPAPER=default.jpg -DBUILD_WITH_QT6=ON -DQT_MAJOR_VERSION=6 -DLIGHTDM_CONFIG_DIR=$out -DDATA_INSTALL_DIR=$out .
        '';
        postInstall = ''
        substituteInPlace "$out/share/xgreeters/lightdm-kde-greeter.desktop" \
        --replace "Exec=lightdm-kde-greeter" "Exec=$out/bin/lightdm-kde-greeter"
        '';
        passthru.xgreeters = pkgs.linkFarm "lightdm-kde-greeter-xgreeters" [{
        path = "${placeholder "out"}/share/xgreeters/lightdm-kde-greeter.desktop";
        name = "lightdm-kde-greeter.desktop";
        }];
    };

    in
    {



    packages = eachSystem
        (pkgs: {
          default = lightdm-kde-greeter {
            inherit pkgs;
          };
        });

  };
}
