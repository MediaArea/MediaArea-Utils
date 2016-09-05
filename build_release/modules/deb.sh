# build_release/modules/deb.sh
# Generate Debian OBS Packages

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function update_dsc () {

    # Arguments :
    # update_dsc $Path_to_obs_project $Archive $DSC

    local OBS_path="$1" Archive="$2" DSC="$3"

    DSC="$OBS_path"/$DSC

    if [ $# -lt 3 ]; then
        print_e "ERROR: insuffisent parameters for update_dsc"
        return 2
    fi

    if ! b.path.file? "$OBS_path"/$Archive && ! b.path.readable? "$OBS_path"/$Archive ; then
        print_e "ERROR: file "$OBS_path"/$Archive not found"
        return 1
    fi

    Size=$(stat -c '%s' "$OBS_path"/$Archive)
    MD5=$(md5sum "$OBS_path"/$Archive |awk '{print $1}')
    SHA1=$(sha1sum "$OBS_path"/$Archive |awk '{print $1}')
    SHA256=$(sha256sum "$OBS_path"/$Archive |awk '{print $1}')

    # For sed, 00* = 0+
    oldMD5="00000000000000000000000000000000 00* $Archive"
    oldSHA1="0000000000000000000000000000000000000000 00* $Archive"
    oldSHA256="0000000000000000000000000000000000000000000000000000000000000000 00* $Archive"

    newMD5="$MD5 $Size $Archive"
    newSHA1="$SHA1 $Size $Archive"
    newSHA256="$SHA256 $Size $Archive"

    if b.path.file? "$DSC" && b.path.readable? "$DSC"; then
        # Handle the longuest strings first, otherwise the shorters
        # get in the way
        $(sed -i "s/$oldSHA256/$newSHA256/g" "$DSC")
        $(sed -i "s/$oldSHA1/$newSHA1/g" "$DSC")
        $(sed -i "s/$oldMD5/$newMD5/g" "$DSC")
    else
       print_e "WARNING: file $DSC not found"
    fi

    return 0
}

function deb_obs () {

    # Arguments :
    # deb_obs $Path_to_obs_project $Archive

    local OBS_path="$1" Archive="$2"
    local Project Version Targets Target DSC

    local deb6="Debian_6.0"
    local deb7="Debian_7.0 xUbuntu_12.04"
    local deb8="Debian_8.0 xUbuntu_14.04 xUbuntu_14.10 xUbuntu_15.04"
    local deb9="xUbuntu_15.10 xUbuntu_16.04 Ubuntu_Next_standard"

    local Targets="$deb7 $deb8 $deb9"

    if [ $# -lt 2 ] ; then
        print_e "ERROR: insuffisent parameters for deb_obs"
        return 2
    fi

    pushd "$OBS_path"
    Project=$(basename "$OBS_path")

    tar xf "$Archive"

    Version=$(cat $Project/Project/version.txt)

    # Create debian package for default target
    cp $Project/Project/GNU/${Archive%%_*}.dsc ${Archive%%_*}_${Version}-1.dsc

    update_dsc "$OBS_path" ${Archive} ${Archive%%_*}_${Version}-1.dsc

    # Create *.debian.tar.xz achive if the package name is *.orig.tar.xz
    if [ "$Archive" == "${Archive%%_*}_${Version}.orig.tar.xz" ] ; then
        mv $Project/debian .
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ${Archive%%_*}_${Version}-1.debian.tar.xz debian)
        rm -fr debian

        update_dsc "$OBS_path" ${Archive%%_*}_${Version}-1.debian.tar.xz ${Archive%%_*}_${Version}-1.dsc
    fi

    # Create debian packages for specifics targets
    for Target in $Project/Project/OBS/*.dsc ; do
        Target="$(basename -s .dsc $Target)"

        # exit if no dsc file found in Project/OBS
        if [ "$Target" == "*" ] ; then
            break
        fi

        # Remove handled targets from the global list
        eval Targets='$'{Targets/'$'$Target/}

        if [ "$Target" == "deb6" ] ; then
            mv $Project/Project/OBS/deb6.debian $Project/debian
            (GZIP=-9 tar -cz --owner=root --group=root --exclude Project/OBS -f ${Archive%%_*}_${Version}-1${Target}.tar.gz $Project)

            cp $Project/Project/OBS/${Target}.dsc .
            update_dsc "$OBS_path" ${Archive%%_*}_${Version}-1${Target}.tar.gz ${Target}.dsc
        else
            mv $Project/Project/OBS/${Target}.debian debian
            (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ${Archive%%_*}_${Version}-1${Target}.debian.tar.xz debian)
            rm -fr debian

            cp $Project/Project/OBS/${Target}.dsc .
            update_dsc "$OBS_path" ${Archive} ${Target}.dsc
            update_dsc "$OBS_path" ${Archive%%_*}_${Version}-1${Target}.debian.tar.xz ${Target}.dsc
        fi

        for DSC in $(eval echo '$'$Target); do
            # Name of the distribution specific dsc on obs is
            # <project name (in lower case)>, not <package name>
            cp ${Target}.dsc ${Project,,}-${DSC}.dsc
        done

        rm ${Target}.dsc
    done

    # If more than one dsc is present
    # we needs a copy of the default dsc for each distribution
    if [ "$(ls 2>/dev/null -b1 *.dsc | wc -l)" -gt "1" ] ; then
        for DSC in $Targets; do
            cp ${Archive%%_*}_${Version}-1.dsc ${Project,,}-${DSC}.dsc
        done
        rm ${Archive%%_*}_${Version}-1.dsc
    fi

    rm -fr $Project
    popd

    return 0
}

