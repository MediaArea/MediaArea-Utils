# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_ubuntu.sh
# Generate the tarballs asked by Preforma — Ubuntu build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function Ubuntu_get_packages () {

    local Arch=$1 Package_type=$2
    local List_packages=$(b.get bang.working_dir)/packages/Ubuntu-$Version.txt

    # If we work with vanilla or updates packages
    if [ -z $Package_type ]; then
        local Destination=buildenv09/Ubuntu-$Version-$Arch
    else
        local Destination=buildenv09/Ubuntu-$Version-$Arch-$Package_type
    fi

    echo "Ubuntu $Version ($Ubuntu_name) $Arch"
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

    rm -fr Packages-$Version-$Arch

}

function Ubuntu_handle_version () {

    Version=$1
    Ubuntu_name=${Ubuntu_names[$Version]}

    # Get the vanilla packages
    Mirror=http://ftp.ubuntu.org/ubuntu
    Mirror=http://ftp.ubuntu.com/ubuntu
    Packages_file_URL_part=$Mirror/dists/$Ubuntu_name/main
    Ubuntu_get_packages amd64
    Ubuntu_get_packages i386

    # Get the updates packages
    #Mirror=http://security.ubuntu.com/ubuntu
    #Packages_file_URL_part=$Mirror/dists/$Ubuntu_name/main
    #Ubuntu_get_packages amd64 updates
    #Ubuntu_get_packages i386 updates

}

function btask.Buildenv_ubuntu.run () {

    echo
    echo "Generate Ubuntu build environment..."

    declare -A Ubuntu_names
    Ubuntu_names[14.04]="trusty"
    Ubuntu_names[15.10]="wily"
    Ubuntu_names[16.04]="xenial"

    Ubuntu_handle_version 14.04
    Ubuntu_handle_version 15.10

    echo "Create Ubuntu package (buildenv09)..."

    cp License*.html buildenv09
    zip -q -r buildenv09-$Date.zip buildenv09
    rm -fr buildenv09

    unset -v Version Ubuntu_names Ubuntu_name
    unset -v Mirror Packages_file_URL_part

}
