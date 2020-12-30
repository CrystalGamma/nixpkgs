#! /usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils curl
set -efuo pipefail

out=$1
shift
server=$1
shift
mydir="$(dirname "$(realpath "$0")")"

cat >$out <<EOF
# DO NOT EDIT! This file is generated automatically.
# Command: $0 $out $server $*
{ fetchurl, mirror }: {
EOF

while test $# -gt 0; do
    path="$1"
    echo fetching from "$server/$path/"
    shift
    curl "$server/$path/" \
        | grep -E '\b[-[:alnum:]]+-[.0-9]+.tar.xz\b' -o \
        | sort | uniq\
        | awk '{print "url = \"'"$server"'/'"$path"'/" $0 ".sha256\""}'\
        | curl -K -\
        | sed 's/\([0-9a-f]\{32\}\) \+\([-a-z0-9]\+\)-\([.0-9]\+\).tar.xz/\1 \2 \3\n/g'\
        | awk -f "$mydir/fetch-kde.awk" path="$path" >>$out
done
echo "}" >>$out
