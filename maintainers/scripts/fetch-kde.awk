# SPDX-License-Identifier: CC0-1.0
{
    print "  " $2 " = {"
    print "    version = \"" $3 "\";"
    print "    src = fetchurl {"
    filename = $2 "-" $3 ".tar.xz"
    print "      url = \"${mirror}/" path "/" filename "\";"
    print "      sha256 = \"" $1 "\";"
    print "      name = \"" filename "\";"
    print "    };"
    print "  };"
}
