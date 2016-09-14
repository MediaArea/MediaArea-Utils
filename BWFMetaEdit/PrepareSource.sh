# BWFMetaEdit/Release/PrepareSource.sh
# Prepare the source of BWFMetaEdit

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
        Source="$WDir"/repos/BWF_MetaEdit
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
    echo "Generate the BM directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/BM
    cp -r "$Source" bwfmetaedit

    echo "2: remove what isn’t wanted..."
    rm -fr bwfmetaedit/.git*
    rm -fr bwfmetaedit/.cvs*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/BM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/bwfmetaedit${Version}.tar.gz bwfmetaedit)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/bwfmetaedit${Version}.tar.bz2 bwfmetaedit)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/bwfmetaedit${Version}.tar.xz bwfmetaedit)

        7za a -t7z -mx=9 -bd ../archives/bwfmetaedit${Version}.7z bwfmetaedit >/dev/null
    fi
}

function _unix_cli () {

    echo
    echo "Generate the BM CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/BM
    mkdir BWFMetaEdit_CLI_GNU_FromSource
    cd BWFMetaEdit_CLI_GNU_FromSource

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
        rm -f GNU/bwfmetaedit.dsc GNU/bwfmetaedit.spec GNU/PKGBUILD
        rm -fr MSVC2010 MSVC2015 OBS
    cd ..
        rm -fr Source/GUI

    echo "3: Autotools..."
    cd Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/BM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/BWFMetaEdit_CLI${Version}_GNU_FromSource.tar.gz BWFMetaEdit_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/BWFMetaEdit_CLI${Version}_GNU_FromSource.tar.bz2 BWFMetaEdit_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/BWFMetaEdit_CLI${Version}_GNU_FromSource.tar.xz BWFMetaEdit_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the BM GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/BM
    mkdir BWFMetaEdit_GUI_GNU_FromSource
    cd BWFMetaEdit_GUI_GNU_FromSource

    cp -r "$Source"/* .
    mv Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x Project/GNU/GUI/autogen.sh
    chmod +x Project/Mac/BR_extension_GUI.sh
    chmod +x Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    rm -fr .cvsignore .git*
    rm -f History_CLI.txt
    rm -fr debian
    cd Project
        rm -fr GNU/CLI Mac/*_CLI.sh
        rm -f GNU/bwfmetaedit.dsc GNU/bwfmetaedit.spec GNU/PKGBUILD
        rm -fr MSVC2010 MSVC2015 OBS
    cd ..

    echo "3: Autotools..."
    cd Project/GNU/GUI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/BM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/BWFMetaEdit_GUI${Version}_GNU_FromSource.tar.gz BWFMetaEdit_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/BWFMetaEdit_GUI${Version}_GNU_FromSource.tar.bz2 BWFMetaEdit_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/BWFMetaEdit_GUI${Version}_GNU_FromSource.tar.xz BWFMetaEdit_GUI_GNU_FromSource)
    fi

}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/BWF_MetaEdit
    rm -fr "$WDir"/BM
    mkdir "$WDir"/BM

    _get_source

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
        rm -fr BM
    fi
}
