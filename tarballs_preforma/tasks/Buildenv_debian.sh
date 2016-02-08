# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_debian.sh
# Generate the tarballs asked by Preforma — Debian build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

# https://github.com/bangsh/bangsh says that “As a convention, the
# other functions defined in the task files should be named with a
# preceding underscore. This is useful to distinguish "where" a
# given function comes from and to avoid name collisions with
# executables in the path.” Except it didn’t work.
# So I use Debian_get_packages instead of _get_packages alone.

function Debian_get_packages () {

    local Arch=$1 Package_type=$2
    local List_packages=$(b.get bang.working_dir)/packages/Debian-$Version.txt

    # If we work with vanilla or updates packages
    if [ -z $Package_type ]; then
        local Destination=buildenv17/Debian-$Version-$Arch
    else
        local Destination=buildenv17/Debian-$Version-$Arch-$Package_type
    fi

    echo "Debian $Version ($Debian_name) $Arch"
    # Verbose mode
    #echo $Mirror

    if b.path.dir? $Destination; then
        rm -fr $Destination
    fi
    mkdir -p $Destination

    # Get the Packages file for this version and architecture
    rm -f Packages*
    if ! wget -nd -q $Packages_file_URL_part/binary-$Arch/Packages.gz || ! b.path.file? Packages.gz; then
        echo
        echo "Error downloading $Packages_file_URL_part/binary-$Arch/Packages.gz"
        echo
        exit 1
    fi
    gzip -d Packages.gz
    mv Packages Packages-$Version-$Arch

    # Download the packages
    # The first occurrence of Package has no $ because it's an
    # assignment.
    while read -r Package || [[ -n $Package ]]; do

        Package_URL_part=$(grep -A 100 "^Package: $Package$" Packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)
        Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
        Package_URL=$Mirror/$Package_URL_part

        if [[ -n $Package_URL_part ]]; then
            # Verbose mode
            #echo -n "Downloading $Package ..."
            if ! wget -P $Destination -nd -q $Package_URL || ! b.path.file? $Destination/$Package_name; then
                echo
                echo "Error while downloading $Package"
                echo "$Package_URL"
                echo
                rm -f $Destination/index.html
            # Verbose mode
            #else
            #    echo " OK"
            fi
        else
            echo "$Package not found in this repository."
        fi

    done < $List_packages

    # Verbose mode
    #echo

}

function Debian_handle_version () {

    Version=$1
    Debian_name=${Debian_names[$Version]}

    # Get the vanilla packages
    Mirror=http://ftp.debian.org/debian
    Packages_file_URL_part=$Mirror/dists/$Debian_name/main
    Debian_get_packages amd64
    Debian_get_packages i386

    # Get the updates packages
    #Mirror=http://security.debian.org/debian-security
    #Packages_file_URL_part=$Mirror/dists/$Debian_name/updates/main
    #Debian_get_packages amd64 updates
    #Debian_get_packages i386 updates

}

function btask.Buildenv_debian.run () {

    echo
    echo "Generate Debian build environment..."
    echo

    declare -a Debian_names
    Debian_names[7]="wheezy"
    Debian_names[8]="jessie"
    Debian_names[9]="stretch"

    #Debian_handle_version 7
    Debian_handle_version 8

    echo
    echo "Create Debian package (buildenv17)..."
    echo
    cp MediaArea/MediaConch_SourceCode/master/License*.html buildenv17
    zip -q -r buildenv17-$Date.zip buildenv17

    unset -v Version Debian_names Debian_name
    unset -v Mirror Packages_file_URL_part

}
