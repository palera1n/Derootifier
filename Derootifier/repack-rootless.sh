#!/bin/sh

### Procursus 3

### INFO: Repacks deb as rootful with iphoneos-arm arch, moves new tweak dir to
###       legacy directory, and resigns. Does not do any further modification.

### Modified by haxi0
### Modified by Nick Chan

export TMPDIR="/var/mobile/.Rootifier"

set -e

mkdir -p "$TMPDIR"

if ! type dpkg-deb >/dev/null 2>&1; then
	echo "Please install dpkg-deb."
fi

if ! type file >/dev/null 2>&1; then
	echo "Please install file."
fi

if ! type fakeroot >/dev/null 2>&1; then
	echo "Please install fakeroot."
fi

if ! ldid 2>&1 | grep -q procursus; then
	echo "Please install Procursus ldid."
fi

if [ "$HELPER_PATH" = "" ]; then
    echo "HELPER_PATH not specified"
    exit 1
fi

export LDID="ldid -Hsha256"

if [ -z "$1" ] || ! file "$1" | grep -q "Debian binary package" ; then
    echo "Usage: $0 [/path/to/deb]"
    exit 1;
fi

echo "Creating workspace"
TEMPDIR_INT="$(mktemp -d)"
TEMPDIR_OLD="$(mktemp -d)"
TEMPDIR_NEW="$(mktemp -d)"

if [ ! -d "$TEMPDIR_OLD" ] || [ ! -d "$TEMPDIR_NEW" ] || [ ! -d "$TEMPDIR_INT" ]; then
	echo "Creating temporary directories failed."
    exit 1;
fi

touch "${TEMPDIR_INT}/.fakeroot_rootifier"
export FAKEROOT="fakeroot -i ${TEMPDIR_INT}/.fakeroot_rootifier -s ${TEMPDIR_INT}/.fakeroot_rootifier --"

### Rootful script start

${FAKEROOT} dpkg-deb -R "$1" "$TEMPDIR_OLD"

if grep -q "^Architecture: iphoneos-arm$" "$TEMPDIR_OLD"/DEBIAN/control; then
    echo "Deb already rootful. Skipping and exiting cleanly."
    rm -rf "$TEMPDIR_OLD" "$TEMPDIR_NEW"
    exit 0;
fi

${FAKEROOT} cp -a "$TEMPDIR_OLD"/DEBIAN "$TEMPDIR_NEW"
sed 's|^Architecture: iphoneos-arm64$|Architecture: iphoneos-arm|' < "$TEMPDIR_OLD"/DEBIAN/control | ${FAKEROOT} tee "$TEMPDIR_NEW"/DEBIAN/control


cp -a "$TEMPDIR_OLD"/var/jb/. "$TEMPDIR_NEW" || true

if [ -d "$TEMPDIR_NEW/usr/lib/TweakInject" ]; then
    mkdir -p "$TEMPDIR_NEW/Library/MobileSubstrate/DynamicLibraries"
    mv "$TEMPDIR_NEW/usr/lib/TweakInject/." "$TEMPDIR_NEW/Library/MobileSubstrate/DynamicLibraries"
    rm -rf "$TEMPDIR_NEW/usr/lib/TweakInject"
fi

find "$TEMPDIR_NEW" -type f -exec sh -c '
set -e

  for file do
    if file -ib "$file" | grep -q "x-mach-binary; charset=binary"; then
    echo "$file"

    MODE="$(stat -c "%a" "${file}")"

    install_name_tool -add_rpath "/usr/lib" "${file}" >/dev/null 2>&1
    install_name_tool -add_rpath "/Library/Frameworks" "${file}" >/dev/null 2>&1

    #if ! grep -q "libroot_get_jbroot_prefix" $file; then
        "${HELPER_PATH}" patch "${file}"
    #fi

    ${LDID} -s "${file}"
    ${FAKEROOT} chmod "${MODE}" \""${file}"\"

fi
  done
' exec-sh {} +


${FAKEROOT} dpkg-deb -Zzstd -b "$TEMPDIR_NEW" "$TMPDIR/$(grep Package: "$TEMPDIR_NEW"/DEBIAN/control | cut -f2 -d ' ')"_"$(grep Version: "$TEMPDIR_NEW"/DEBIAN/control | cut -f2 -d ' ')"_"$(grep Architecture: "$TEMPDIR_NEW"/DEBIAN/control | cut -f2 -d ' ')".deb

find "$TMPDIR"/* ! -name '*iphoneos-arm.deb' -delete

### Real script end

echo "Cleaning up"
rm -rf "$TEMPDIR_OLD" "$TEMPDIR_NEW" "$TEMPDIR_INT"
