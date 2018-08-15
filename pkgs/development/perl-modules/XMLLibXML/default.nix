{buildPerlPackage, XMLSAX, DevelChecklib, pkgs}:
buildPerlPackage rec {
  name = "XML-LibXML-2.0132";
  src = pkgs.fetchurl {
    url = "mirror://cpan/authors/id/S/SH/SHLOMIF/${name}.tar.gz";
    sha256 = "0xnl281hb590i287fxpl947f1s4zl9dnvc4ajvsqi89w23im453j";
  };
  patches = [ ./dont-check-libxml2.patch ];
  SKIP_SAX_INSTALL = 1;
  buildInputs = [ pkgs.libxml2 pkgs.zlib DevelChecklib ];
  preConfigure = "rm -r inc/Devel";
  propagatedBuildInputs = [ XMLSAX ];
  nativeBuildInputs = [ pkgs.libxml2 ];
  #makeMakerFlags = "LIBS='-L${pkgs.libxml2.out}/lib -L${pkgs.zlib}/lib -lxml2 -lm -lz -ldl' INC='-I${pkgs.libxml2.dev}/include/libxml2'";

  # https://rt.cpan.org/Public/Bug/Display.html?id=122958
  preCheck = ''
    rm t/32xpc_variables.t
  '';
}
