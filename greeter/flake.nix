{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:

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

    lightdm-kde-greeter = { pkgs, ...}: pkgs.stdenv.mkDerivation(finalAttrs: {
        pname = "lightdm-kde-greeter";
        name = "lightdm-kde-greeter";
        version = "0.1";

        src = pkgs.fetchurl {
        url = "https://invent.kde.org/golubevan/lightdm-kde-greeter/-/archive/mr-small-fixes/lightdm-kde-greeter-mr-small-fixes.tar.gz";
        hash = "sha256-+2MC6kNFnDI42dFEauDgoD8ptc0PSGZ4jLMbSv+7jeA=";
        };
        buildInputs = with pkgs; [ kdePackages.qtbase kdePackages.qtshadertools qt6.full kdePackages.plasma-workspace kdePackages.qtshadertools kdePackages.kcmutils kdePackages.kcmutils lightdm gtk2 kdePackages.kauth kdePackages.kconfig kdePackages.kconfigwidgets kdePackages.kcoreaddons kdePackages.kdeclarative kdePackages.ki18n kdePackages.kiconthemes kdePackages.kpackage kdePackages.kservice kdePackages.networkmanager-qt kdePackages.libplasma kdePackages.qtsvg kdePackages.ksvg kdePackages.kirigami kdePackages.qtvirtualkeyboard];
        nativeBuildInputs = with pkgs; [ cmake kdePackages.extra-cmake-modules qt6.wrapQtAppsHook pkg-config ];
        dontUseCmakeConfigure=true;
        buildPhase = ''
        cmake -DGREETER_IMAGES_DIR=$out/images -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_WITH_QT6=ON -DQT_MAJOR_VERSION=6 -DLIGHTDM_CONFIG_DIR=$out -DGREETER_DEFAULT_WALLPAPER=/mnt/potd/wallpaper.jpg -DDATA_INSTALL_DIR=$out/share .
        '';
        postInstall = ''
        substituteInPlace "$out/share/xgreeters/lightdm-kde-greeter.desktop" \
        --replace "Exec=lightdm-kde-greeter" "Exec=$out/bin/lightdm-kde-greeter"
        '';

        postFixup = ''
        patchelf \
        --add-needed ${pkgs.libGL}/lib/libGL.so.1 \
        $out/bin/lightdm-kde-greeter

        patchelf \
        --add-needed ${pkgs.libGL}/lib/libGL.so.1 \
        $out/bin/lightdm-kde-greeter-rootimage

        substituteInPlace "$out/share/systemd/user/lightdm-kde-greeter-wifikeeper.service" \
        --replace "ExecStart=/lightdm-kde-greeter-wifikeeper" "ExecStart=$out/bin/lightdm-kde-greeter-wifikeeper"

        substituteInPlace "$out/share/dbus-1/system-services/org.kde.kcontrol.kcmlightdm.service" \
        --replace "Exec=lib64/libexec/kcmlightdmhelper" "Exec=$out/lib64/libexec/kcmlightdmhelper"

        mkdir $out/lib/qt-6
        mv $out/lib/plugins $out/lib/qt-6/
        '';

        passthru.xgreeters = pkgs.linkFarm "lightdm-kde-greeter-xgreeters" [{
          path = "${finalAttrs.finalPackage}/share/xgreeters/lightdm-kde-greeter.desktop";
          name = "lightdm-kde-greeter.desktop";
        }];
    });

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
