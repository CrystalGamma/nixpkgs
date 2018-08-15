{pkgs, installSystem}:
let inherit ((import  ../../../../../lib ).systems) elaborate;
in if pkgs.stdenv.hostPlatform == elaborate installSystem
then pkgs
else (import ../../../../.. {localSystem=pkgs.stdenv.buildPlatform;crossSystem = if pkgs.stdenv.buildPlatform != elaborate installSystem then installSystem else null;})
