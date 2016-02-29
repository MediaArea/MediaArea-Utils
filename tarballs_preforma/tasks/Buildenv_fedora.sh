# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_fedora.sh
# Generate the tarballs asked by Preforma — Fedora build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

#function getFedoraUpdatedPackages () {
#
#    if [ "${arch}" = "i386" ]; then
#        dlArch="i686"
#    else
#        dlArch=${arch}
#    fi
#
#    while read -r package || [[ -n "$package" ]]; do
#        Package_URL_part=$(grep -A 100 "<name>${package}</name>" $repoFileUpdate | grep "location" | egrep -m1 "${dlArch}|noarch" | cut -d\" -f2)
#        if [ "$Package_URL_part" != "" ]; then
#            Package_URL="${repo}/updates/${releasever}/${arch}/${Package_URL_part}"
#            Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
#            if ! b.path.file? "$tmp/$Package_name"; then
#                if ! wget -q -N -P $tmp "${Package_URL}" || ! b.path.file? "$tmp/$Package_name"; then
#                    echo "Error downloading \"${package}\" : ${Package_URL}"
#                    rm -f "$tmp/index.html"
#                fi
#            fi
#        else
#            Package_URL_part=$(grep -A 100 "<name>${package}</name>" $repoFile | grep "location" | egrep -m1 "${dlArch}|noarch" | cut -d\" -f2)
#            Package_URL="${repo}/releases/${releasever}/Everything/${arch}/os/${Package_URL_part}"
#            Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
#            if ! b.path.file? "$tmp/$Package_name"; then
#                if ! wget -q -N -P $tmp "${Package_URL}" || ! b.path.file? "$tmp/$Package_name"; then
#                    echo "Error downloading \"${package}\" : ${Package_URL}"
#                    rm -f "$tmp/index.html"
#                fi
#            fi
#        fi
#    done < "$packagesListFile"
#
#}

function Fedora_get_packages () {

    local Arch=$1 Package_type=$2
    local List_packages=$(b.get bang.working_dir)/packages/Fedora-$Version.txt
    local Package_arch Repo_file

    if [ $Arch = "i386" ]; then
        Package_arch="i686"
    else
        Package_arch=$Arch
    fi

    # If we work with vanilla or updates packages
    if [ -z $Package_type ]; then
        local Mirror_current=$Mirror/$Arch/os
        local Destination=buildenv13/Fedora-$Version-$Package_arch
    else
        local Mirror_current=$Mirror/$Arch
        local Destination=buildenv13/Fedora-$Version-$Package_arch-$Package_type
    fi
    local Repodata_dir=$Mirror_current/repodata

    echo "Fedora $Version $Package_arch"

    if b.path.dir? $Destination; then
        rm -fr $Destination
    fi
    mkdir -p $Destination

    # Get the repomd.xml file for this version and architecture
    rm -f repomd.xml
    if ! wget -nd -q $Repodata_dir/repomd.xml || ! b.path.file? repomd.xml; then
        echo
        echo "Error downloading $Repodata_dir/repomd.xml"
        echo
        exit 1
    fi
    Repo_file=$(grep "\-primary.xml.gz" repomd.xml | cut -d\" -f2 | cut -d\/ -f2 | cut -d. -f -2)
    rm -f repomd.xml

    # Get the primary.xml file for this version and architecture
    rm -f $Repo_file.gz *primary.xml
    if ! wget -nd -q $Repodata_dir/$Repo_file.gz || ! b.path.file? $Repo_file.gz; then
        echo
        echo "Error downloading $Repodata_dir/$Repo_file.gz"
        echo
        exit 1
    fi
    gzip -d $Repo_file.gz

    # Download the packages
    while read -r Package || [[ -n $Package ]]; do

        Package_URL_part=$(grep -A 100 "<name>$Package</name>" $Repo_file |grep "location href" | grep -m1 "$Package_arch\|noarch" | cut -d\" -f2)
        Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
        Package_URL=$Mirror_current/$Package_URL_part

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

    rm -f $Repo_file

}

function Fedora_handle_version () {

    Version=$1

    # Get the vanilla packages
    Mirror=http://download.fedoraproject.org/pub/fedora/linux/releases/$Version/Everything
    Fedora_get_packages x86_64
    Fedora_get_packages i386

    # Get the updates packages
    #Mirror=http://download.fedoraproject.org/pub/fedora/linux/updates/$Version
    #Fedora_get_packages x86_64 updates
    #Fedora_get_packages i386 updates

}

function btask.Buildenv_fedora.run () {

    echo
    echo "Generate Fedora build environment..."

    #Fedora_handle_version 22
    Fedora_handle_version 23

    echo "Create Fedora package (buildenv13)..."

    cp License*.html buildenv13
    zip -q -r buildenv13-$Date.zip buildenv13
    rm -fr buildenv13

    unset -v Version Mirror

}
