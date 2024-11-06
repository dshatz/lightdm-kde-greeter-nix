Use lightdm-kde-greeter (https://invent.kde.org/plasma/lightdm-kde-greeter) on nixos.

## Usage
In your system `flake.nix`:
```nix
inputs = {
  ...
  lightdm-kde-greeter.url = "github:dshatz/lightdm-kde-greeter-nix";
};
outputs = { self, nixpkgs, lightdm-kde-greeter}@inputs: {
   nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      # customize to your system
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
      ];
    };
};
```

In your `configuration.nix`:
```nix
services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.kde = {
      enable = true;
      enable-high-dpi = true;
    };
};
```

## Wallpaper
Wallpaper is always loaded from `/mnt/potd/wallpaper.jpg`.
If you want the greeter wallpaper to be the same as your Plasma POTD wallpaper, add this to your nix config:

*replace <user> with the user whose POTD wallpaper to use*

*also replace filename in `device=` with correct filename*
```nix
fileSystems."/mnt/potd/wallpaper.jpg" = {
    depends = [
        "/home/<user>"
    ];
    device = "/home/<user>/.cache/plasma_engine_potd/bing:3840:2160";
    fsType = "none";
    options = [
      "bind"
      "ro" 
    ];
};
```


## KCM
KCM module will not work on nixos as it relies on write access to `/etc/lightdm` directory.


## Status
This is a basic working nix implementation but in the current form it's not particularly customizable.
Anyone with a better knowledge of nix can submit PRs - I'll be glad to check them out.
