# MOVMetaEdit/Release/PrepareSource.sh
# Prepare the source of MOVMetaEdit

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of QCTools
    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        Source="$WDir"/repos/MOVMetaEdit
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
    echo "Generate the MM directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MM
    cp -r "$Source" movmetaedit

    echo "2: remove what isn’t wanted..."
    rm -fr movmetaedit/.git*
    rm -fr movmetaedit/.cvs*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/movmetaedit${Version}.tar.gz movmetaedit)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/movmetaedit${Version}.tar.bz2 movmetaedit)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/movmetaedit${Version}.tar.xz movmetaedit)

        7za a -t7z -mx=9 -bd ../archives/movmetaedit${Version}.7z movmetaedit >/dev/null

        mkdir ../archives/obs

        cp ../archives/movmetaedit${Version}.tar.gz ../archives/obs/movmetaedit${Version}-1.tar.gz

        cp ../archives/movmetaedit${Version}.tar.xz ../archives/obs/movmetaedit${Version}.orig.tar.xz

        cp "$WDir/MM/movmetaedit/Project/GNU/movmetaedit.spec" ../archives/obs
        cp "$WDir/MM/movmetaedit/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/movmetaedit${Version}-1.tar.gz ../archives/obs/PKGBUILD
        deb_obs movmetaedit "$WDir/MM/movmetaedit" "$WDir/archives/obs/movmetaedit${Version}.orig.tar.xz"
    fi
}

function _unix_cli () {

    echo
    echo "Generate the MM CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MM
    mkdir MOVMetaEdit_CLI_GNU_FromSource
    cd MOVMetaEdit_CLI_GNU_FromSource

    cp -r "$Source"/* .
    mv Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x Project/GNU/CLI/autogen.sh
    chmod +x Project/Mac/BR_extension_CLI.sh
    chmod +x Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    rm -fr .git*
    rm -fr debian
    pushd Project
        rm -fr Qt
        rm -f GNU/movmetaedit.dsc GNU/movmetaedit.spec GNU/PKGBUILD
        rm -fr MSVC2015
    popd
    rm -fr Source/GUI

    echo "3: Autotools..."
    pushd Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1
    popd

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MOVMetaEdit_CLI${Version}_GNU_FromSource.tar.gz MOVMetaEdit_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MOVMetaEdit_CLI${Version}_GNU_FromSource.tar.bz2 MOVMetaEdit_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MOVMetaEdit_CLI${Version}_GNU_FromSource.tar.xz MOVMetaEdit_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the MM GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MM
    mkdir MOVMetaEdit_GUI_GNU_FromSource
    cd MOVMetaEdit_GUI_GNU_FromSource

    cp -r "$Source"/* .
    mv Project/Qt/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x Project/Mac/BR_extension_GUI.sh
    chmod +x Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    rm -fr .git*
    rm -fr debian
    pushd Project
        rm -fr GNU/
        rm -fr MSVC2015
    popd

    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MOVMetaEdit_GUI${Version}_GNU_FromSource.tar.gz MOVMetaEdit_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MOVMetaEdit_GUI${Version}_GNU_FromSource.tar.bz2 MOVMetaEdit_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MOVMetaEdit_GUI${Version}_GNU_FromSource.tar.xz MOVMetaEdit_GUI_GNU_FromSource)
    fi

}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/MOVMetaEdit
    rm -fr "$WDir"/MM
    mkdir "$WDir"/MM

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$Source/Project/version.txt")
    fi

    if [ "$Target" = "sa" ] || [ "$Target" = "ai" ] || [ "$Target" = "all" ]; then
        _source_package
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "all" ]; then
        _unix_cli
        _unix_gui
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr MM
    fi
}
