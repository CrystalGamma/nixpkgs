{ config, lib, pkgs, ... }:

with lib;

let
  blCfg = config.boot.loader;
  dtCfg = config.hardware.deviceTree;
  cfg = blCfg.generic-extlinux-compatible;

  timeoutStr = if blCfg.timeout == null then "-1" else toString blCfg.timeout;

  # The builder used to write during system activation
  builder = import ./extlinux-conf-builder.nix { inherit pkgs; };
  # The builder exposed in populateCmd, which runs on the build architecture
  populateBuilder = import ./extlinux-conf-builder.nix { pkgs = pkgs.buildPackages; };
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

      populateCmd = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Contains the builder command used to populate an image,
          honoring all options except the <literal>-c &lt;path-to-default-configuration&gt;</literal>
          argument.
          Useful to have for sdImage.populateRootCommands
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
          WARNING: the build script will clean out any files in this directory
          that it didn't create, so this directory has to be otherwise empty!
          Has to be on the same file system as the configuration file.
        '';
      };
    };
  };

  config = let
    builderArgs = "-g ${toString cfg.configurationLimit} -d ${cfg.imagePath} -o ${cfg.configPath} -t ${timeoutStr}" + lib.optionalString (dtCfg.name != null) " -n ${dtCfg.name}";
  in
    mkIf cfg.enable {
      system.build.installBootLoader = "${builder} ${builderArgs} -c";
      system.boot.loader.id = "generic-extlinux-compatible";

      boot.loader.generic-extlinux-compatible.populateCmd = "${populateBuilder} ${builderArgs}";
    };
}
