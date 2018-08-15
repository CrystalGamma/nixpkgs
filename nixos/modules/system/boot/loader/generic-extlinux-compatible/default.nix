{ config, lib, pkgs, ... }:

with lib;

let
  blCfg = config.boot.loader;
  cfg = blCfg.generic-extlinux-compatible;

  timeoutStr = if blCfg.timeout == null then "-1" else toString blCfg.timeout;

  builder = {installSystem}: import ./extlinux-conf-builder.nix { pkgs = import ../installer-pkgs.nix {inherit pkgs installSystem;}; };
in
{
  options = {
    boot.loader.generic-extlinux-compatible = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to generate an extlinux-compatible configuration file.
          For instance, U-Boot's generic distro boot support uses this file
          format.

          See <link xlink:href="http://git.denx.de/?p=u-boot.git;a=blob;f=doc/README.distro;hb=refs/heads/master">U-boot's documentation</link>
          for more information.
        '';
      };

      configurationLimit = mkOption {
        default = 20;
        example = 10;
        type = types.int;
        description = ''
          Maximum number of configurations in the boot menu.
        '';
      };

      configPath = mkOption {
        default = "/boot/extlinux/extlinux.conf";
        type = types.path;
        description = ''
          The path where to create the configuration file.
          Has to be on the same file system as the kernel and initial ramdisk images.
        '';
      };
      imagePath = mkOption {
        default = "/boot/nixos/";
        type = types.path;
        description = ''
          The directory where to store kernel and initial ramdisk images.
          WARNING: the build script will clean out any files it does not know,
          so this directory has to be otherwise empty!
          Has to be on the same file system as the configuration file.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    system.build.installBootLoader = {installSystem}: "${builder {inherit installSystem;}} -g ${toString cfg.configurationLimit} -d ${cfg.imagePath} -o ${cfg.configPath} -t ${timeoutStr} -c";
    system.boot.loader.id = "generic-extlinux-compatible";
  };
}
