{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:

    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;



      inherit (nixpkgs.lib) genAttrs optional;
      eachSystem = f: genAttrs
        [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ]
        (system: f nixpkgs.legacyPackages.${system});

      lightdm-kde-greeter = { pkgs, ... }:
      pkgs.stdenv.mkDerivation {
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
        cmakeFlags = [
          "-DGREETER_IMAGES_DIR=images"
          "-DBUILD_TESTING=ON"
          "-DCMAKE_BUILD_TYPE=Debug"
          "-DCMAKE_INSTALL_PREFIX=$out"
          "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
          "-DECM_ENABLE_SANITIZERS='address'"
          "-DGREETER_DEFAULT_WALLPAPER=default.jpg"
          "-DBUILD_WITH_QT6=ON"
          "-DQT_MAJOR_VERSION=6"
          "-DLIGHTDM_CONFIG_DIR=$out"
          "-DDATA_INSTALL_DIR=$out"
        ];
        buildPhase = ''
          cmake -DGREETER_IMAGES_DIR=images -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=$out -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DECM_ENABLE_SANITIZERS='address' -DGREETER_DEFAULT_WALLPAPER=default.jpg -DBUILD_WITH_QT6=ON -DQT_MAJOR_VERSION=6 -DLIGHTDM_CONFIG_DIR=$out -DDATA_INSTALL_DIR=$out .
        '';
        postInstall = ''
          ls -lah $out
        '';
      };

    in
    {

      nixosModules.default = { config, pkgs, ... }:
        let
          dmcfg = config.services.xserver.displayManager;
          ldmcfg = dmcfg.lightdm;
          cfg = ldmcfg.greeters.kde;
          inherit (nixpkgs.lib) mkOption types mkIf mkDefault;
        in
        {


          options = {

            services.xserver.displayManager.lightdm.greeters.kde = {

              enable = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether to enable lightdm-mini-greeter as the lightdm greeter.

                  Note that this greeter starts only the default X session.
                  You can configure the default X session using
                  [](#opt-services.displayManager.defaultSession).
                '';
              };

              user = mkOption {
                type = types.str;
                default = "root";
                description = ''
                  The user to login as.
                '';
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Extra configuration that should be put in the lightdm-kde-greeter.conf
                  configuration file.
                '';
              };

            };

          };

          config = mkIf (ldmcfg.enable && cfg.enable) {
            services.xserver.displayManager.lightdm.greeters.gtk.enable = false;
            services.xserver.displayManager.lightdm.greeter = mkDefault {
              package = pkgs.lightdm-kde-greeter.xgreeters;
              name = "lightdm-kde-greeter";
            };

            environment.etc."lightdm/lightdm-kde-greeter.conf".source = "lightdm-kde-greeter.conf";

          };
        };

        packages = eachSystem
        (pkgs: {
          default = lightdm-kde-greeter {
            inherit pkgs;
            # splash = "custom splash text";
          };
        });
#       packages.x86_64-linux.default = lightdm-kde-greeter { inherit pkgs; };

  };
}
