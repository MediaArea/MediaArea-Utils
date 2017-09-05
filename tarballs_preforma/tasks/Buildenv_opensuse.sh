# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_opensuse.sh
# Generate the tarballs asked by Preforma — Opensuse build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function Opensuse_get_packages () {

    local Arch=$1 Package_type=$2
    local List_packages=$(b.get bang.working_dir)/packages/Opensuse-$Version.txt
    local Repo_file

    # If we work with vanilla or updates packages
    if [ -z $Package_type ]; then
        local Destination=buildenv21/Opensuse-$Version-$Arch
    else
        local Destination=buildenv21/Opensuse-$Version-$Arch-$Package_type
    fi
    local Repodata_dir=$Mirror/repodata

    echo "Opensuse $Version $Arch"

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

    rm -f $Repo_file

}

function Opensuse_handle_version () {

    Version=$1

    # Get the vanilla packages
    if [ $Version = "13.2" ]; then
        Mirror=http://download.opensuse.org/distribution/$Version/repo/oss/suse
        Opensuse_get_packages i586
        Opensuse_get_packages x86_64
    else 
        Mirror=http://download.opensuse.org/distribution/leap/$Version/repo/oss/suse
        Opensuse_get_packages x86_64
    fi

    # Get the updates packages
    #if [ $Version = "13.2" ]; then
    #    Mirror=http://download.opensuse.org/update/$Version/oss
    #    Opensuse_get_packages i586 updates
    #    Opensuse_get_packages x86_64 updates
    #else
    #    Mirror=http://download.opensuse.org/update/leap/$Version/oss
    #    Opensuse_get_packages x86_64 updates
    #fi

}

function btask.Buildenv_opensuse.run () {

    echo
    echo "Generate Opensuse build environment..."

    #Opensuse_handle_version "13.2"
    Opensuse_handle_version "42.3"

    echo "Create the Opensuse package (buildenv21)..."

    cp License*.html buildenv21
    cp -f $(b.get bang.working_dir)/readmes/Readme_opensuse.txt buildenv21/Read_me.txt
    zip -q -r buildenv21-$Date.zip buildenv21
    rm -fr buildenv21

    unset -v Version Mirror

}
