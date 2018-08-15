{ config, pkgs, lib, ... }:

with lib;

{

  config = mkIf config.boot.isContainer {

    # Disable some features that are not useful in a container.
    sound.enable = mkDefault false;
    services.udisks2.enable = mkDefault false;
    powerManagement.enable = mkDefault false;

    networking.useHostResolvConf = mkDefault true;

    # Containers should be light-weight, so start sshd on demand.
    services.openssh.startWhenNeeded = mkDefault true;

    # Shut up warnings about not having a boot loader.
    system.build.installBootLoader = {installSystem}: let pkgs_ = import ../system/boot/loader/installer-pkgs.nix {inherit pkgs installSystem;}; in "${pkgs_.coreutils}/bin/true";

    # Not supported in systemd-nspawn containers.
    security.audit.enable = false;

  };

}
