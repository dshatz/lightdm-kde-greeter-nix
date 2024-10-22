{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lightdm-kde-greeter.url = "path:./greeter";
  };

  outputs = { self, nixpkgs, lightdm-kde-greeter }@inputs:
    let
    inherit (nixpkgs.lib) mkOption types mkIf mkDefault genAttrs;
          eachSystem = f: genAttrs
        [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ]
        (system: f nixpkgs.legacyPackages.${system});
        in
    {

      nixosModules.default = { config, pkgs, ... }:
        let
          dmcfg = config.services.xserver.displayManager;
          ldmcfg = dmcfg.lightdm;
          cfg = ldmcfg.greeters.kde;
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
              package = lightdm-kde-greeter.defaultPackage.x86_64-linux.xgreeters;
              name = "lightdm-kde-greeter";
            };

            environment.etc."lightdm/lightdm-kde-greeter.conf".source = builtins.toPath "${lightdm-kde-greeter.defaultPackage.x86_64-linux}/lightdm-kde-greeter.conf";

          };
        };

        packages = lightdm-kde-greeter.packages;
        defaultPackage = lightdm-kde-greeter.defaultPackage;

#         packages = eachSystem
#             (pkgs: {
#               default = lightdm-kde-greeter.defaultPackage.x86_64-linux {
#                 inherit pkgs;
#               };
#         });
  };
}
