# DVAnalyzer/Release/PrepareSource.sh
# Prepare the source of DVAnalyzer

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of DVAnalyzer
    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        Source="$WDir"/repos/DV_Analyzer
        getRepo $Repo "$Source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$Source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

    MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi
    ZL_gs=""
    if [ $(b.opt.get_opt --zl-gs) ]; then
        ZL_gs="--zl-gs $(sanitize_arg $(b.opt.get_opt --zl-gs))"
    fi

    # MediaInfoLib (will also bring ZenLib and zlib)
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if b.path.dir? "$WDir/../upgrade_version/MediaInfoLib" ; then
         $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -sp "$WDir/../upgrade_version/MediaInfoLib" -wp "$WDir" $ZL_gs -${Target} -na
    else
        $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -wp "$WDir" $MIL_gs $ZL_gs -${Target} -na
    fi
}


function _unix_cli () {

    echo
    echo "Generate the DA CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DA
    mkdir DVAnalyzer_CLI_GNU_FromSource
    cd DVAnalyzer_CLI_GNU_FromSource

    cp -r "$Source" AVPS_DV_Analyzer
    mv AVPS_DV_Analyzer/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x AVPS_DV_Analyzer/Project/GNU/CLI/autogen.sh
    chmod +x AVPS_DV_Analyzer/Project/Mac/BR_extension_CLI.sh
    chmod +x AVPS_DV_Analyzer/Project/Mac/mkdmg.sh

    # ZenLib and MediaInfoLib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

    echo "2: remove what isn’t wanted..."
    cd AVPS_DV_Analyzer
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/GUI Mac/*_GUI.sh
            rm -f GNU/dvanalyzer.dsc GNU/dvanalyzer.spec GNU/PKGBUILD
            rm -fr MSVC2008 MSVC2010 MSVC2015
        cd ..
        rm -fr Source/GUI
    cd ..

    echo "3: Autotools..."
    cd AVPS_DV_Analyzer/Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/DA
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/DVAnalyzer_CLI${Version}_GNU_FromSource.tar.gz DVAnalyzer_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/DVAnalyzer_CLI${Version}_GNU_FromSource.tar.bz2 DVAnalyzer_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/DVAnalyzer_CLI${Version}_GNU_FromSource.tar.xz DVAnalyzer_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the DA GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DA
    mkdir DVAnalyzer_GUI_GNU_FromSource
    cd DVAnalyzer_GUI_GNU_FromSource

    cp -r "$Source" AVPS_DV_Analyzer
    mv AVPS_DV_Analyzer/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x AVPS_DV_Analyzer/Project/GNU/GUI/autogen.sh
    chmod +x AVPS_DV_Analyzer/Project/Mac/BR_extension_GUI.sh
    chmod +x AVPS_DV_Analyzer/Project/Mac/mkdmg.sh

    # ZenLib and MediaInfoLib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

    echo "2: remove what isn’t wanted..."
    cd AVPS_DV_Analyzer
        rm -fr .cvsignore .git*
        rm -f History_CLI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/CLI Mac/*_CLI.sh
            rm -f GNU/dvanalyzer.dsc GNU/dvanalyzer.spec GNU/PKGBUILD
            rm -fr MSVC2008 MSVC2010 MSVC2015
        cd ..
    cd ..

    echo "3: Autotools..."
    cd AVPS_DV_Analyzer/Project/GNU/GUI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/DA
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/DVAnalyzer_GUI${Version}_GNU_FromSource.tar.gz DVAnalyzer_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/DVAnalyzer_GUI${Version}_GNU_FromSource.tar.bz2 DVAnalyzer_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/DVAnalyzer_GUI${Version}_GNU_FromSource.tar.xz DVAnalyzer_GUI_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the DA all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DA
    mkdir dvanalyzer_AllInclusive
    cd dvanalyzer_AllInclusive

    cp -r "$Source" AVPS_DV_Analyzer

    # Dependencies
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/ZenLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/MediaInfoLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/zlib .

    echo "2: configure dependencies for use static runtime..."
    find zlib ZenLib MediaInfoLib -type f -name "*.vcxproj" -exec \
         sed -i \
             -e 's/MultiThreadedDebugDLL/MultiThreadedDebug/g' \
             -e 's/MultiThreadedDLL/MultiThreaded/g' {} \;

    echo "3: remove what isn’t wanted..."
    rm -fr dvanalyzer/.git*
    rm -fr dvanalyzer/.cvs*
    rm -fr dvanalyzer/debian

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/DA
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/dvanalyzer${Version}_AllInclusive.7z dvanalyzer_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the DA directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DA
    cp -r "$Source" AVPS_DV_Analyzer

    echo "2: remove what isn’t wanted..."
    rm -fr dvanalyzer/.git*
    rm -fr dvanalyzer/.cvs*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/DA
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/dvanalyzer${Version}.tar.gz AVPS_DV_Analyzer)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/dvanalyzer${Version}.tar.bz2 AVPS_DV_Analyzer)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/dvanalyzer${Version}.tar.xz AVPS_DV_Analyzer)

        mkdir ../archives/obs

        cp ../archives/dvanalyzer${Version}.tar.gz ../archives/obs/dvanalyzer${Version}-1.tar.gz
        cp ../archives/dvanalyzer${Version}.tar.xz ../archives/obs/dvanalyzer${Version}.orig.tar.xz

        cp "$WDir/DA/AVPS_DV_Analyzer/Project/GNU/dvanalyzer.spec" ../archives/obs
        cp "$WDir/DA/AVPS_DV_Analyzer/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/dvanalyzer${Version}-1.tar.gz ../archives/obs/PKGBUILD
        deb_obs dvanalyzer "$WDir/DA/AVPS_DV_Analyzer" "$WDir/archives/obs/dvanalyzer${Version}.orig.tar.xz"
    fi
}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/DV_Analyzer
    rm -fr "$WDir"/DA
    mkdir "$WDir"/DA

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
        rm -fr DA
    fi
}
