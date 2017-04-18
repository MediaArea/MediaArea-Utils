# prepare_source/modules/arch.sh
# Update Arch PKGBUILD

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function update_pkgbuild () {

    # Arguments :
    # update_pkgbuild $Archive $PKGBUILD

    # TODO: Handle more than one file in PKGBUILD
    # TODO: Handle sha1sum & sha256sum arrays

    local Archive="$1" PKGBUILD="$2"


    if [ $# -lt 2 ]; then
        echo "Insuffisent parameters for update_PKGBUILD"
        return 1
    fi

    if ! b.path.file? "$Archive" || ! b.path.readable? "$Archive" ; then
        print_e "ERROR: file "$Archive" not found"
        return 1
    fi

    if ! b.path.file? "$PKGBUILD" || ! b.path.readable? "$PKGBUILD" ; then
        print_e "ERROR: file "$DSC" not found"
        return 1
    fi

    local OldMD5="00000000000000000000000000000000"
    local MD5=$(md5sum "$Archive" |awk '{print $1}')

    sed -i "s/$OldMD5/$MD5/g" "$PKGBUILD"

    return 0
}
