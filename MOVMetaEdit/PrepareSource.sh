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
        Source="$WDir"/repos/MOV_MetaEdit
        getRepo $Repo "$Source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$Source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

    # Dependency : ZenLib
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    $(b.get bang.src_path)/bang run PrepareSource.sh -p ZenLib -wp "$WDir" $ZL_gs -${Target} -na
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
        cp "$WDir/MM/movmetaedit/Project/GNU/movmetaedit.spec" ../archives/obs
        cp "$WDir/MM/movmetaedit/Project/GNU/movmetaedit.dsc" ../archives/obs
        cp "$WDir/MM/movmetaedit/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/movmetaedit${Version}-1.tar.gz ../archives/obs/PKGBUILD
        update_dsc ../archives/obs/movmetaedit${Version}-1.tar.gz ../archives/obs/movmetaedit.dsc
    fi
}

function _unix_cli () {

    echo
    echo "Generate the MM CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MM
    mkdir MOVMetaEdit_CLI_GNU_FromSource
    cd MOVMetaEdit_CLI_GNU_FromSource

    cp -r "$Source" .
    mv MOV_MetaEdit/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x MOV_MetaEdit/Project/GNU/CLI/autogen.sh
    chmod +x MOV_MetaEdit/Project/Mac/BR_extension_CLI.sh
    chmod +x MOV_MetaEdit/Project/Mac/mkdmg.sh

    # Dependency : ZenLib
    cp -r "$WDir"/ZL/ZenLib_compilation_under_unix ZenLib

    echo "2: remove what isn’t wanted..."
    pushd MOV_MetaEdit
        rm -fr .git*
        rm -fr debian
        pushd Project
            rm -fr Qt
            rm -f GNU/movmetaedit.dsc GNU/movmetaedit.spec GNU/PKGBUILD
            rm -fr MSVC2015
        popd
        rm -fr Source/GUI
    popd

    echo "3: Autotools..."
    pushd ZenLib/Project/GNU/Library
    ./autogen.sh > /dev/null 2>&1
    popd
    pushd MOV_MetaEdit/Project/GNU/CLI
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

    cp -r "$Source"/ .
    mv MOV_MetaEdit/Project/Qt/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x MOV_MetaEdit/Project/Mac/BR_extension_GUI.sh
    chmod +x MOV_MetaEdit/Project/Mac/mkdmg.sh

    echo "2: remove what isn’t wanted..."
    pushd MOV_MetaEdit
        rm -fr .git*
        rm -fr debian
        pushd Project
            rm -fr GNU/
            rm -fr MSVC2015
        popd
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

function _all_inclusive () {

    echo
    echo "Generate the MM all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MM
    mkdir movmetaedit_AllInclusive
    cd movmetaedit_AllInclusive

    cp -r "$Source" MOV_MetaEdit

    # Dependencies
    # Dependency : ZenLib
    cp -r "$WDir"/ZL/ZenLib_AllInclusive ZenLib

    echo "2: configure dependencies for use static runtime..."
    find ZenLib MOV_MetaEdit -type f -name "*.vcxproj" -exec \
         sed -i \
             -e 's/MultiThreadedDebugDLL/MultiThreadedDebug/g' \
             -e 's/MultiThreadedDLL/MultiThreaded/g' {} \;

    echo "3: remove what isn’t wanted..."
    rm -fr MOV_MetaEdit/.git*
    rm -fr MOV_MetaEdit/debian

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MM
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/movmetaedit${Version}_AllInclusive.7z movmetaedit_AllInclusive >/dev/null
    fi

}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/MOV_MetaEdit
    rm -fr "$WDir"/MM
    mkdir "$WDir"/MM

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$Source/Project/version.txt")
    fi

    if [ "$Target" = "sa" ] || [ "$Target" = "all" ]; then
        _source_package
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "all" ]; then
        _unix_cli
        _unix_gui
    fi

    if [ "$Target" = "ai" ] || [ "$Target" = "all" ]; then
        _all_inclusive
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr MM
    fi
}
