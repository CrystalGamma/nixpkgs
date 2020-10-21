{ lib
, stdenv
, fetchurl
, meson
, ninja
, pkg-config
, libftdi1
, libusb1
, pciutils
}:

stdenv.mkDerivation rec {
  pname = "flashrom";
  version = "1.2";

  src = fetchurl {
    url = "https://download.flashrom.org/releases/flashrom-v${version}.tar.bz2";
    sha256 = "0ax4kqnh7kd3z120ypgp73qy1knz47l6qxsqzrfkd97mh5cdky71";
  };

  mesonFlags = lib.optionals (!stdenv.hostPlatform.isx86) [ "-Dpciutils=false" ];
  nativeBuildInputs = [ meson pkg-config ninja ];
  buildInputs = [ libftdi1 libusb1 pciutils ];

  meta = with lib; {
    homepage = "http://www.flashrom.org";
    description = "Utility for reading, writing, erasing and verifying flash ROM chips";
    license = licenses.gpl2;
    maintainers = with maintainers; [ funfunctor fpletz ];
    platforms = platforms.all;
    broken = stdenv.isDarwin; # requires DirectHW
  };
}
