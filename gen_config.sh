#!/bin/sh

set -e

# $1 = name of package
# $2 = MSYS2 MSYSTEM value

package="$1"
MSYSTEM="$2"

case "$MSYSTEM" in
  MINGW32|MINGW64|CLANG32|CLANG64|CLANGARM64|MINGW32|MINGW64)
    ;;
  *)
    echo "Unsupported or unrecognised Environment: $MSYSTEM">&2
    exit 2;;
esac

if [ ! -f '/etc/msystem' ]; then
  echo "/etc/msystem not found - is this an MSYS2 Installation?">&2
  exit 1
fi

. '/etc/msystem'

if [ x"$MSYSTEM_CHOST" != x"$MINGW_CHOST" ]; then
  echo "Unexpected result from /etc/msystem:">&2
  echo " - MSYSTEM_CHOST and MINGW_CHOST not equal">&2
  exit 1
elif [ x"$MSYSTEM_PREFIX" != x"$MINGW_PREFIX" ]; then
  echo "Unexpected result from /etc/msystem:">&2
  echo " - MSYSTEM_PREFIX and MINGW_PREFIX not equal">&2
  exit 1
fi

opam_escape='s/\\/\\\\/g;s/%/%%/g;s/"/\\"/g'

eval "carch=\"\$(echo \"\$MSYSTEM_CARCH\" | sed -e '$opam_escape')\""
eval "chost=\"\$(echo \"\$MSYSTEM_CHOST\" | sed -e '$opam_escape')\""
eval "root=\"\$(echo \"\$MSYSTEM_PREFIX\" | sed -e '$opam_escape')\""
eval "native_root=\
\"\$(cygpath -w \"\$MSYSTEM_PREFIX\" | sed -e '$opam_escape')\""
eval "package_prefix=\
\"\$(echo \"\$MINGW_PACKAGE_PREFIX\" | sed -e '$opam_escape')\""

cat > "$package.config" <<EOF
opam-version: "2.0"
variables {
  msystem: "$MSYSTEM"
  carch: "$carch"
  chost: "$chost"
  root: "$root"
  native-root: "$native_root"
  package-prefix: "$package_prefix"
}
EOF
