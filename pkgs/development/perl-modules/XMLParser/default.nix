{buildPerlPackage, LWP, pkgs}:
buildPerlPackage {
  name = "XML-Parser-2.44";
  src = pkgs.fetchurl {
    url = mirror://cpan/authors/id/T/TO/TODDR/XML-Parser-2.44.tar.gz;
    sha256 = "05ij0g6bfn27iaggxf8nl5rhlwx6f6p6xmdav6rjcly3x5zd1s8s";
  };
  patches = [ ./no-english.patch ];
  postPatch = if pkgs.stdenv.isCygwin then ''
    sed -i"" -e "s@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. \$Config{_exe};@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. (\$^O eq 'cygwin' ? \"\" : \$Config{_exe});@" inc/Devel/CheckLib.pm
  '' else null;
  makeMakerFlags = "EXPATLIBPATH=${pkgs.expat.out}/lib EXPATINCPATH=${pkgs.expat.dev}/include";
  propagatedBuildInputs = [ LWP ];
}
