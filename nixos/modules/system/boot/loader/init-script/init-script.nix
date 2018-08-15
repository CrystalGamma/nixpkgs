{ config, lib, pkgs, ... }:

with lib;

let

  initScriptBuilder = {installSystem}: let pkgs_ = import ../installer-pkgs.nix {inherit installSystem pkgs;}; in pkgs_.substituteAll {
    src = ./init-script-builder.sh;
    isExecutable = true;
    inherit (pkgs_) bash;
    path = [pkgs_.coreutils pkgs_.gnused pkgs_.gnugrep];
  };

in

{

  ###### interface

  options = {

    boot.loader.initScript = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Some systems require a /sbin/init script which is started.
          Or having it makes starting NixOS easier.
          This applies to some kind of hosting services and user mode linux.

          Additionally this script will create
          /boot/init-other-configurations-contents.txt containing
          contents of remaining configurations. You can copy paste them into
          /sbin/init manually running a rescue system or such.
        '';
      };
    };

  };


  ###### implementation

  config = mkIf config.boot.loader.initScript.enable {

    system.build.installBootLoader = initScriptBuilder;

  };

}
