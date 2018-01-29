# RAWCooked/Release/PrepareSource.sh
# Prepare the source of RAWCooked

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of RAWCooked
    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        Source="$WDir"/repos/RAWCooked
        getRepo $Repo "$Source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$Source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

}

function _source_package () {

    echo
    echo "Generate the RC directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/RC
    cp -r "$Source" rawcooked

    echo "2: remove what isn’t wanted..."
    rm -fr rawcooked/.git*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/RC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/rawcooked${Version}.tar.gz rawcooked)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/rawcooked${Version}.tar.bz2 rawcooked)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/rawcooked${Version}.tar.xz rawcooked)

        7za a -t7z -mx=9 -bd ../archives/rawcooked${Version}.7z rawcooked >/dev/null

        mkdir ../archives/obs

        cp ../archives/rawcooked${Version}.tar.gz ../archives/obs/rawcooked${Version}-1.tar.gz
        cp ../archives/rawcooked${Version}.tar.xz ../archives/obs/rawcooked${Version}.orig.tar.xz

        cp "$WDir/RC/rawcooked/Project/GNU/rawcooked.spec" ../archives/obs
        cp "$WDir/RC/rawcooked/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/rawcooked${Version}-1.tar.gz ../archives/obs/PKGBUILD
        deb_obs rawcooked "$WDir/RC/rawcooked" "$WDir/archives/obs/rawcooked${Version}.orig.tar.xz"
    fi
}

function _unix_cli () {

    echo
    echo "Generate the RC CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/RC
    mkdir RAWCooked_CLI_GNU_FromSource
    cd RAWCooked_CLI_GNU_FromSource

    cp -r "$Source"/* .
    mv Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x Project/GNU/CLI/autogen.sh
    chmod +x Project/Mac/BR_extension_CLI.sh
    chmod +x Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    rm -fr .cvsignore .git*
    rm -f History_GUI.txt
    rm -fr debian
    cd Project
        rm -fr GNU/GUI Mac/*_GUI.sh
        rm -f GNU/rawcooked.dsc GNU/rawcooked.spec GNU/PKGBUILD
        rm -fr MSVC2010 MSVC2015
    cd ..
        rm -fr Source/GUI

    echo "3: Autotools..."
    cd Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/RC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/RAWCooked_CLI${Version}_GNU_FromSource.tar.gz RAWCooked_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/RAWCooked_CLI${Version}_GNU_FromSource.tar.bz2 RAWCooked_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/RAWCooked_CLI${Version}_GNU_FromSource.tar.xz RAWCooked_CLI_GNU_FromSource)
    fi

}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/RAWCooked
    rm -fr "$WDir"/RC
    mkdir "$WDir"/RC

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$Source/Project/version.txt")
    fi

    if [ "$Target" = "sa" ] || [ "$Target" = "ai" ] || [ "$Target" = "all" ]; then
        _source_package
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "all" ]; then
        _unix_cli
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr RC
    fi
}
