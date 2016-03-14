# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_ubuntu.sh
# Generate the tarballs asked by Preforma — Ubuntu build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function Ubuntu_get_packages () {

    local Arch=$1
    #local Updates_mirror=http://archive.ubuntu.com/ubuntu
    #local Updates_Packages_gz=$Updates_mirror/dists/$Ubuntu_name-updates/main/binary-$Arch/Packages.gz
    #local Security_mirror=http://security.ubuntu.com/ubuntu
    #local Security_Packages_gz=$Security_mirror/dists/$Ubuntu_name/main/binary-$Arch/Packages.gz
    local Main_mirror=http://ftp.ubuntu.com/ubuntu
    local Main_Packages_gz=$Main_mirror/dists/$Ubuntu_name/main/binary-$Arch/Packages.gz

    #http://archive.ubuntu.com/ubuntu/dists/trusty/universe/binary-amd64/
    #local Universe_mirror=
    #local Universe_Packages_gz=

    local List_packages=$(b.get bang.working_dir)/packages/Ubuntu-$Version.txt
    local Destination=buildenv09/Ubuntu-$Version-$Arch
    local Package_URL_part Package_name Package_URL

    echo "Ubuntu $Version ($Ubuntu_name) $Arch"

    if b.path.dir? $Destination; then
        rm -fr $Destination
    fi
    mkdir -p $Destination

    # Get the file Packages.gz for the updates repo
    #rm -f Updates_packages*
    #if ! wget -nd -q $Updates_Packages_gz || ! b.path.file? Packages.gz; then
    #    echo
    #    echo "Error downloading $Updates_Packages_gz"
    #    echo
    #    exit 1
    #fi
    #gzip -d Packages.gz
    #mv Packages Updates_packages-$Version-$Arch

    # Get the file Packages.gz for the security repo
    #rm -f Security_packages*
    #if ! wget -nd -q $Security_Packages_gz || ! b.path.file? Packages.gz; then
    #    echo
    #    echo "Error downloading $Security_Packages_gz"
    #    echo
    #    exit 1
    #fi
    #gzip -d Packages.gz
    #mv Packages Security_packages-$Version-$Arch

    # Get the file Packages.gz for the main repo
    rm -f Main_packages*
    if ! wget -nd -q $Main_Packages_gz || ! b.path.file? Packages.gz; then
        echo
        echo "Error downloading $Main_Packages_gz"
        echo
        exit 1
    fi
    gzip -d Packages.gz
    mv Packages Main_packages-$Version-$Arch

    # Download the packages
    while read -r Package || [[ -n $Package ]]; do

        ## First we try the updates repo

        #Package_URL_part=$(grep -A 100 "^Package: $Package$" Updates_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)

        #if [[ -n $Package_URL_part ]]; then

        #    Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
        #    Package_URL=$Updates_mirror/$Package_URL_part
    
        #    # Verbose mode
        #    echo -n "Downloading (from updates repo) $Package ..."
        #    if ! wget -P $Destination -nd -q $Package_URL || ! b.path.file? $Destination/$Package_name; then
        #        echo
        #        echo "Error while downloading $Package"
        #        echo "$Package_URL"
        #        echo
        #        rm -f $Destination/index.html
        #    # Verbose mode
        #    else
        #        echo " OK"
        #    fi

        # If the package is not in the updates repo, we try the
        # security repo
        #else

        #    Package_URL_part=$(grep -A 100 "^Package: $Package$" Security_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)
    
        #    if [[ -n $Package_URL_part ]]; then
    
        #        Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
        #        Package_URL=$Security_mirror/$Package_URL_part
        #
        #        # Verbose mode
        #        echo -n "Downloading (from security repo) $Package ..."
        #        if ! wget -P $Destination -nd -q $Package_URL || ! b.path.file? $Destination/$Package_name; then
        #            echo
        #            echo "Error while downloading $Package"
        #            echo "$Package_URL"
        #            echo
        #            rm -f $Destination/index.html
        #        # Verbose mode
        #        else
        #            echo " OK"
        #        fi
    
        #    # If the package is neither in the updates or the
        #    # security repo, we try the main repo
        #    else
    
                Package_URL_part=$(grep -A 100 "^Package: $Package$" Main_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)

                if [[ -n $Package_URL_part ]]; then

                    Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
                    Package_URL=$Main_mirror/$Package_URL_part
            
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

                # If the package is neither in the updates, 
                # security or main repo, we try the universe repo
#                else
#
#                    Package_URL_part=$(grep -A 100 "^Package: $Package$" Universe_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)
#    
#                    if [[ -n $Package_URL_part ]]; then
#    
#                        Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
#                        Package_URL=$Universe_mirror/$Package_URL_part
#                
#                        # Verbose mode
#                        echo -n "Downloading (from universe repo) $Package ..."
#                        if ! wget -P $Destination -nd -q $Package_URL || ! b.path.file? $Destination/$Package_name; then
#                            echo
#                            echo "Error while downloading $Package"
#                            echo "$Package_URL"
#                            echo
#                            rm -f $Destination/index.html
#                        # Verbose mode
#                        else
#                            echo " OK"
#                        fi

                    else
                        #echo "$Package not found neither in updates, security, main or universe repositories."
                        echo "$Package not found in main repositories."
                    #fi

                #fi
    
            fi

        #fi
    
    done < $List_packages

    # Verbose mode
    #echo

    #rm -f Updates_packages-$Version-$Arch
    #rm -f Security_packages-$Version-$Arch
    rm -f Main_packages-$Version-$Arch

}

function Ubuntu_handle_version () {

    Version=$1
    Ubuntu_name=${Ubuntu_names[$Version]}

    Ubuntu_get_packages amd64
    Ubuntu_get_packages i386

}

function btask.Buildenv_ubuntu.run () {

    echo
    echo "Generate Ubuntu build environment..."

    declare -A Ubuntu_names
    Ubuntu_names[14.04]="trusty"
    Ubuntu_names[15.10]="wily"
    Ubuntu_names[16.04]="xenial"

    #Ubuntu_handle_version 14.04
    Ubuntu_handle_version 15.10

    echo "Create Ubuntu package (buildenv09)..."

    cp License*.html buildenv09
    zip -q -r buildenv09-$Date.zip buildenv09
    rm -fr buildenv09

    unset -v Ubuntu_names Version Ubuntu_name

}
