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

    local Arch=$1
    local Security_mirror=http://security.debian.org/debian-security
    local Security_Packages_gz=$Security_mirror/dists/$Debian_name/updates/main/binary-$Arch/Packages.gz
    local Main_mirror=http://ftp.debian.org/debian
    local Main_Packages_gz=$Main_mirror/dists/$Debian_name/main/binary-$Arch/Packages.gz
    local List_packages=$(b.get bang.working_dir)/packages/Debian-$Version.txt
    local Destination=buildenv17/Debian-$Version-$Arch
    local Package_URL_part Package_name Package_URL

    echo "Debian $Version ($Debian_name) $Arch"

    if b.path.dir? $Destination; then
        rm -fr $Destination
    fi
    mkdir -p $Destination
 
    # Get the file Packages.gz for the security repo
    rm -f Security_packages*
    if ! wget -nd -q $Security_Packages_gz || ! b.path.file? Packages.gz; then
        echo
        echo "Error downloading $Security_Packages_gz"
        echo
        exit 1
    fi
    gzip -d Packages.gz
    mv Packages Security_packages-$Version-$Arch

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
    # (the first occurrence of Package has no $ because it's an
    # assignment)
    while read -r Package || [[ -n $Package ]]; do

        Package_URL_part=$(grep -A 100 "^Package: $Package$" Security_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)

        if [[ -n $Package_URL_part ]]; then

            Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
            Package_URL=$Security_mirror/$Package_URL_part
    
            # Verbose mode
            #echo -n "Downloading (from security repo) $Package ..."
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

            Package_URL_part=$(grep -A 100 "^Package: $Package$" Main_packages-$Version-$Arch |grep -m1 Filename |cut -d " " -f2)
            Package_name=$(echo $Package_URL_part | awk -F/ '{print $NF}')
            Package_URL=$Main_mirror/$Package_URL_part
    
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
                echo "$Package not found neither in security or base repository."
            fi

        fi

    done < $List_packages

    # Verbose mode
    #echo

    rm -f Main_packages-$Version-$Arch
    rm -f Security_packages-$Version-$Arch

}

function Debian_handle_version () {

    Version=$1
    Debian_name=${Debian_names[$Version]}

    Debian_get_packages amd64
    Debian_get_packages i386

}

function btask.Buildenv_debian.run () {

    echo
    echo "Generate Debian build environment..."

    declare -a Debian_names
    Debian_names[7]="wheezy"
    Debian_names[8]="jessie"
    Debian_names[9]="stretch"

    #Debian_handle_version 7
    Debian_handle_version 8

    echo "Create Debian package (buildenv17)..."

    cp License*.html buildenv17
    cp -f $(b.get bang.working_dir)/readmes/Readme_debian.txt buildenv17/Read_me.txt
    zip -q -r buildenv17-$Date.zip buildenv17
    rm -fr buildenv17

    unset -v Debian_names Version Debian_name

}
