{ stdenv
, fetchFromGitHub
, jdk, ant
, unzip, zip  # needed for jar canonicalization
}:

stdenv.mkDerivation  rec {
  name = "lombok-1.16.8";
  src = fetchFromGitHub {
    owner = "rzwitserloot";
    repo = "lombok";
    rev = "26ad9e7f5f4de77436d3d63e4a43e8cb77621c15";
    sha256 = "1jjjr5lf7fjaywf9grkb009al2prbg2dkcdj4bhjpnpx3b8gnc8k";
  };
  util = ../../../../build-support/release/functions.sh;
  buildInputs = [ jdk ant unzip zip ];
  buildPhase = "ant";
  installPhase = ''
    source $util
    canonicalizeJar dist/lombok.jar
    mkdir -p $out/share/java
    cp dist/lombok.jar $out/share/java
  '';
  meta = with stdenv.lib; {
    description = "A library that can write a lot of boilerplate for your Java project";
    platforms = platforms.all;
    license = licenses.mit;
    homepage = https://projectlombok.org/;
    maintainer = [ maintainers.CrystalGamma ];
  };
}
