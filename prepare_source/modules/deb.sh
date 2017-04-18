# prepare_source/modules/deb.sh
# Generate Debian OBS Packages

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function update_dsc () {
    # Arguments :
    # update_dsc $Archive $DSC

    local Archive="$1" DSC="$2"

    local Filename=$(basename "$Archive")

    if [ $# -lt 2 ] ; then
        print_e "ERROR: insuffisent parameters for update_dsc"
        return 1
    fi

    if ! b.path.file? "$Archive" || ! b.path.readable? "$Archive" ; then
        print_e "ERROR: file "$Archive" not found"
        return 1
    fi

    if ! b.path.file? "$DSC" || ! b.path.readable? "$DSC" ; then
        print_e "ERROR: file "$DSC" not found"
        return 1
    fi

    local Size=$(stat -c '%s' "$Archive")
    local MD5=$(md5sum "$Archive" |awk '{print $1}')
    local SHA1=$(sha1sum "$Archive" |awk '{print $1}')
    local SHA256=$(sha256sum "$Archive" |awk '{print $1}')

    # For sed, 00* = 0+
    local oldMD5="00000000000000000000000000000000 00* $Filename"
    local oldSHA1="0000000000000000000000000000000000000000 00* $Filename"
    local oldSHA256="0000000000000000000000000000000000000000000000000000000000000000 00* $Filename"

    local newMD5="$MD5 $Size $Filename"
    local newSHA1="$SHA1 $Size $Filename"
    local newSHA256="$SHA256 $Size $Filename"

    sed -i "s/$oldSHA256/$newSHA256/g" "$DSC"
    sed -i "s/$oldSHA1/$newSHA1/g" "$DSC"
    sed -i "s/$oldMD5/$newMD5/g" "$DSC"

    return 0
}

function deb_obs () {

    # Arguments :
    # deb_obs $Project

    local Project="$1" Sources="$2" Archive="$3"

    local Filename=$(basename "${Archive%_*}")
    local Output=$(dirname "$Archive")

    if [ "$#" -lt 3 ] ; then
        print_e "ERROR: insuffisent parameters for deb_obs"
        return 1
    fi

    local deb6="Debian_6.0"
    local deb7="Debian_7.0 xUbuntu_12.04"
    local deb8="Debian_8.0 xUbuntu_14.04 xUbuntu_14.10 xUbuntu_15.04"
    local deb9="xUbuntu_15.10 xUbuntu_16.04 xUbuntu_16.10 Ubuntu_Next_standard Debian_Next_ga"

    local Targets="$deb7 $deb8 $deb9"

    pushd "$Sources"

    # Create debian package for default target
    cp "Project/GNU/$Filename.dsc" "$Output/$Filename$Version-1.dsc"

    update_dsc "$Archive" "$Output/$Filename$Version-1.dsc"

    # Create *.debian.tar.xz achive if the package name is *.orig.tar.xz
    if [ $(basename "$Archive") == "$Filename$Version.orig.tar.xz" ] ; then
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f "$Output/$Filename$Version-1.debian.tar.xz" debian)

        update_dsc "$Output/$Filename$Version-1.debian.tar.xz" "$Output/$Filename$Version-1.dsc"
    fi

    # Create debian packages for specifics targets
    local Target
    for Target in Project/OBS/*.dsc ; do
        Target=$(basename -s .dsc "$Target")

        # exit if no dsc file found in Project/OBS
        if [ "$Target" == "*" ] ; then
            break
        fi

        # Remove handled targets from the global list
        eval Targets='$'{Targets/'$'$Target/}

        if [ -e debian ] ; then
            rm -fr debian
        fi

        if [ "$Target" == "deb6" ] ; then

            mv "Project/OBS/$Target.debian" debian
            (GZIP=-9 tar -cz --owner=root --group=root --exclude Project/OBS -f "$Output/$Filename$Version-1$Target.tar.gz" .)

            cp "Project/OBS/$Target.dsc" .
            update_dsc "$Output/$Filename$Version-1$Target.tar.gz" "$Target.dsc"
        else
            mv "Project/OBS/${Target}.debian" debian
            (XZ_OPT=-9e tar -cJ --owner=root --group=root -f "$Output/$Filename$Version-1$Target.debian.tar.xz" debian)

            cp "Project/OBS/$Target.dsc" .
            update_dsc "$Archive" "$Target.dsc"
            update_dsc "$Output/$Filename$Version-1$Target.debian.tar.xz" "$Target.dsc"
        fi

        local DSC
        for DSC in $(eval echo '$'$Target); do
            # Name of the distribution specific dsc on obs is
            # <project name (in lower case)>, not <package name>
            cp "$Target.dsc" "$Output/${Project,,}-$DSC.dsc"
        done

        rm "$Target.dsc"
    done

    # If more than one dsc is present
    # we needs a copy of the default dsc for each distribution
    if [ "$(ls 2>/dev/null -b1 $Output/*.dsc | wc -l)" -gt 1 ] ; then
        local DSC
        for DSC in $Targets; do
            cp "$Output/$Filename$Version-1.dsc" "$Output/${Project,,}-$DSC.dsc"
        done
        rm "$Output/$Filename$Version-1.dsc"
    fi
    popd

    return 0
}