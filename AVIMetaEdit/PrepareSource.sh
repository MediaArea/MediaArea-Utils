# AVIMetaEdit/Release/PrepareSource.sh
# Prepare the source of AVIMetaEdit

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
        Source="$WDir"/repos/AVIMetaEdit
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
    echo "Generate the AM directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AM
    cp -r "$Source" avimetaedit

    echo "2: remove what isn’t wanted..."
    rm -fr avimetaedit/.git*
    rm -fr avimetaedit/.cvs*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/AM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/avimetaedit${Version}.tar.gz avimetaedit)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/avimetaedit${Version}.tar.bz2 avimetaedit)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/avimetaedit${Version}.tar.xz avimetaedit)

        7za a -t7z -mx=9 -bd ../archives/avimetaedit${Version}.7z avimetaedit >/dev/null

        mkdir ../archives/obs

        cp ../archives/avimetaedit${Version}.tar.gz ../archives/obs/avimetaedit${Version}-1.tar.gz
        cp ../archives/avimetaedit${Version}.tar.xz ../archives/obs/avimetaedit${Version}.orig.tar.xz

        cp "$WDir/AM/avimetaedit/Project/GNU/avimetaedit.spec" ../archives/obs
        cp "$WDir/AM/avimetaedit/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/avimetaedit${Version}-1.tar.gz ../archives/obs/PKGBUILD
        deb_obs avimetaedit "$WDir/AM/avimetaedit" "$WDir/archives/obs/avimetaedit${Version}.orig.tar.xz"
    fi
}

function _unix_cli () {

    echo
    echo "Generate the AM CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AM
    mkdir AVIMetaEdit_CLI_GNU_FromSource
    cd AVIMetaEdit_CLI_GNU_FromSource

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
        rm -f GNU/avimetaedit.dsc GNU/avimetaedit.spec GNU/PKGBUILD
        rm -fr MSVC2010 MSVC2015
    cd ..
        rm -fr Source/GUI

    echo "3: Autotools..."
    cd Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/AM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/AVIMetaEdit_CLI${Version}_GNU_FromSource.tar.gz AVIMetaEdit_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/AVIMetaEdit_CLI${Version}_GNU_FromSource.tar.bz2 AVIMetaEdit_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/AVIMetaEdit_CLI${Version}_GNU_FromSource.tar.xz AVIMetaEdit_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the AM GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AM
    mkdir AVIMetaEdit_GUI_GNU_FromSource
    cd AVIMetaEdit_GUI_GNU_FromSource

    cp -r "$Source"/* .
    mv Project/QtCreator/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x Project/QtCreator/prepare
    chmod +x Project/Mac/BR_extension_GUI.sh
    chmod +x Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    rm -fr .cvsignore .git*
    rm -f History_CLI.txt
    rm -fr debian
    cd Project
        rm -fr GNU/CLI Mac/*_CLI.sh
        rm -f GNU/avimetaedit.dsc GNU/avimetaedit.spec GNU/PKGBUILD
        rm -fr MSVC2010 MSVC2015
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/AM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/AVIMetaEdit_GUI${Version}_GNU_FromSource.tar.gz AVIMetaEdit_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/AVIMetaEdit_GUI${Version}_GNU_FromSource.tar.bz2 AVIMetaEdit_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/AVIMetaEdit_GUI${Version}_GNU_FromSource.tar.xz AVIMetaEdit_GUI_GNU_FromSource)
    fi
}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/AVIMetaEdit
    rm -fr "$WDir"/AM
    mkdir "$WDir"/AM

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
        rm -fr AM
    fi
}
