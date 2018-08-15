{ stdenv, fetchurl, pciutils }: with stdenv.lib;

stdenv.mkDerivation rec {
  name = "gnu-efi-${version}";
  version = "3.0.8";

  src = fetchurl {
    url = "mirror://sourceforge/gnu-efi/${name}.tar.bz2";
    sha256 = "08mpw8s79azip9jbzm6msq0999pnkqzd82axydrcyyynm276s03n";
  };

  buildInputs = [ pciutils ];

  hardeningDisable = [ "stackprotector" ];

  makeFlags = [
    "PREFIX=\${out}"
    "CC=${stdenv.cc.targetPrefix}gcc"
    "AS=${stdenv.cc.targetPrefix}as"
    "LD=${stdenv.cc.targetPrefix}ld"
    "AR=${stdenv.cc.targetPrefix}ar"
    "RANLIB=${stdenv.cc.targetPrefix}ranlib"
    "OBJCOPY=${stdenv.cc.targetPrefix}objcopy"
  ] ++ stdenv.lib.optional stdenv.isAarch32 "ARCH=arm"
    ++ stdenv.lib.optional stdenv.isAarch64 "ARCH=aarch64"
    ++ stdenv.lib.optional stdenv.hostPlatform.isx86_64 "ARCH=x86_64";

  # x86-64 systemd also wants ia32 headers (at least when cross-building)
  postInstall = if stdenv.hostPlatform.isx86_64 then "make -C inc PREFIX=$out ARCH=ia32 install" else "";

  meta = with stdenv.lib; {
    description = "GNU EFI development toolchain";
    homepage = https://sourceforge.net/projects/gnu-efi/;
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
