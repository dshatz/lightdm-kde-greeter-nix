{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lightdm-kde-greeter.url = "git+file:.?dir=greeter";
  };

  outputs = { self, nixpkgs, lightdm-kde-greeter }@inputs:
    let
    supportedSystems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ];
    inherit (nixpkgs.lib) mkOption types mkIf mkDefault genAttrs;
      eachSystem = f: genAttrs
        supportedSystems
        (system: f nixpkgs.legacyPackages.${system});
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

        in
    {

      nixosModules.default = { config, pkgs, ... }:
        let
          dmcfg = config.services.xserver.displayManager;
          ldmcfg = dmcfg.lightdm;
          cfg = ldmcfg.greeters.kde;

          kdeGreeterConf = pkgs.writeText "lightdm-kde-greeter.conf" ''
          # SPDX-FileCopyrightText: None
          # SPDX-License-Identifier: CC0-1.0
          #
          # LightDM KDE Configuration
          # Available configuration options listed below.
          #
          # General greeter settings:
          #  theme-name = greeter theme to use
          #  enable-high-dpi = false|true ("false" by default)  Enable high DPI scaling and pixmaps. (Qt::AA_EnableHighDpiScaling and Qt::AA_UseHighDpiPixmaps are enabled)
          #  hide-network-widget = false|true ("false" by default) The theme should not show the network setting, even if there is one
          #
          # Theme "userbar" settings:
          #  Background = Background file to use, should be readable by all users
          #  BackgroundFillMode = number, [0-6], The following modes are supported:
          #    0: Stretch
          #    1: PreserveAspectFit
          #    2: PreserveAspectCrop
          #    3: Tile
          #    4: TileVertically
          #    5: TileHorizontally
          #    6: Pad (the image is not transformed)

          [greeter]
          enable-high-dpi=${nixpkgs.lib.boolToString cfg.enable-high-dpi}
          theme-name=userbar
          #hide-network-widget=false

          [lightdm_theme_userbar]
          Background=${ldmcfg.background}
          #BackgroundFillMode='';
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

              enable-high-dpi = mkOption {
                type = types.bool;
                default = true;
              };

            };

          };

          config = mkIf (ldmcfg.enable && cfg.enable) {
            services.xserver.displayManager.lightdm.greeters.gtk.enable = false;
            services.xserver.displayManager.lightdm.greeter = mkDefault {
              package = lightdm-kde-greeter.packages.x86_64-linux.default.xgreeters;
              name = "lightdm-kde-greeter";
            };

            environment.etc."lightdm/lightdm-kde-greeter.conf".source = kdeGreeterConf;

          };
        };

        packages = forAllSystems
        (system: rec {
          default = lightdm-kde-greeter.packages.${system}.default;
        });

  };
}
