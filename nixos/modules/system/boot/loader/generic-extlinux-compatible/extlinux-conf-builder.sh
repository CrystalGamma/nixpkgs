#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
    echo "usage: $0 -t <timeout> -c <path-to-default-configuration> [-d <boot-dir>] [-o <configuration-file-path>] [-g <num-generations>] [-n <dtbName>]" >&2
    exit 1
}

timeout=                # Timeout in centiseconds
default=                # Default configuration
target=/boot/nixos            # Target directory
conf=/boot/extlinux/extlinux.conf
numGenerations=0        # Number of other generations to include in the menu

while getopts "t:c:d:o:g:n:" opt; do
    case "$opt" in
        t) # U-Boot interprets '0' as infinite and negative as instant boot
            if [ "$OPTARG" -lt 0 ]; then
                timeout=0
            elif [ "$OPTARG" = 0 ]; then
                timeout=-10
            else
                timeout=$((OPTARG * 10))
            fi
            ;;
        c) default="$OPTARG" ;;
        d) target="$OPTARG" ;;
        o) conf="$OPTARG" ;;
        g) numGenerations="$OPTARG" ;;
        n) dtbName="$OPTARG" ;;
        \?) usage ;;
    esac
done

[ "$timeout" = "" -o "$default" = "" ] && usage

mkdir -p $target
mkdir -p $(dirname $conf)

# Convert a path to a file in the Nix store such as
# /nix/store/<hash>-<name>/file to <hash>-<name>-<file>.
cleanName() {
    local path="$1"
    echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

# Copy a file from the Nix store to $target.
declare -A filesCopied

copyToKernelsDir() {
    local src=$(readlink -f "$1")
    local dst="$target/$(cleanName $src)"
    # Don't copy the file if $dst already exists.  This means that we
    # have to create $dst atomically to prevent partially copied
    # kernels or initrd if this script is ever interrupted.
    if ! test -e $dst; then
        local dstTmp=$dst.tmp.$$
        cp -r $src $dstTmp
        mv $dstTmp $dst
    fi
    filesCopied[$dst]=1
    result=$dst
}

# Copy its kernel, initrd and dtbs to $target, and echo out an
# extlinux menu entry
addEntry() {
    local path=$(readlink -f "$1")
    local tag="$2" # Generation number or 'default'

    if ! test -e $path/kernel -a -e $path/initrd; then
        return
    fi

    copyToKernelsDir "$path/kernel"; kernel=$result
    copyToKernelsDir "$path/initrd"; initrd=$result
    dtbDir=$(readlink -m "$path/dtbs")
    if [ -e "$dtbDir" ]; then
        copyToKernelsDir "$dtbDir"; dtbs=$result
    fi

    timestampEpoch=$(stat -L -c '%Z' $path)

    timestamp=$(date "+%Y-%m-%d %H:%M" -d @$timestampEpoch)
    nixosLabel="$(cat $path/nixos-version)"
    extraParams="$(cat $path/kernel-params)"

    echo
    echo "LABEL nixos-$tag"
    if [ "$tag" = "default" ]; then
        echo "  MENU LABEL NixOS - Default"
    else
        echo "  MENU LABEL NixOS - Configuration $tag ($timestamp - $nixosLabel)"
    fi
    # write paths relative to the mount points, since some bootloaders (e. g. petitboot) do not handle relative paths well
    echo "  LINUX /$(realpath --relative-to="$(stat -c "%m" $conf)" $kernel)"
    echo "  INITRD /$(realpath --relative-to="$(stat -c "%m" $conf)" $initrd)"
    if [ -d "$dtbDir" ]; then
        # if a dtbName was specified explicitly, use that, else use FDTDIR
        if [ -n "$dtbName" ]; then
            echo "  FDT /$(realpath --relative-to="$(stat -c "%m" $conf)" $dtbs)/${dtbName}"
        else
            echo "  FDTDIR /$(realpath --relative-to="$(stat -c "%m" $conf)" $dtbs)"
        fi
    else
        if [ -n "$dtbName" ]; then
            echo "Explicitly requested dtbName $dtbName, but there's no FDTDIR - bailing out." >&2
            exit 1
        fi
    fi
    echo "  APPEND init=$path/init $extraParams"
}

tmpFile="$conf.tmp.$$"

cat > $tmpFile <<EOF
# Generated file, all changes will be lost on nixos-rebuild!

# Change this to e.g. nixos-42 to temporarily boot to an older configuration.
DEFAULT nixos-default

MENU TITLE ------------------------------------------------------------
TIMEOUT $timeout
EOF

addEntry $default default >> $tmpFile

if [ "$numGenerations" -gt 0 ]; then
    # Add up to $numGenerations generations of the system profile to the menu,
    # in reverse (most recent to least recent) order.
    for generation in $(
            (cd /nix/var/nix/profiles && ls -d system-*-link) \
            | sed 's/system-\([0-9]\+\)-link/\1/' \
            | sort -n -r \
            | head -n $numGenerations); do
        link=/nix/var/nix/profiles/system-$generation-link
        addEntry $link $generation
    done >> $tmpFile
fi

if ! test -e $conf; then touch $conf; fi
mv -f $tmpFile $conf

# Remove obsolete files from $target.
for fn in $target/*; do
    if ! test "${filesCopied[$fn]}" = 1; then
        if [[ $conf != $fn* ]]; then
            echo "Removing no longer needed boot file: $fn"
            chmod +w -- "$fn"
            rm -rf -- "$fn"
        fi
    fi
done
