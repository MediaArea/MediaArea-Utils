# ADCTest/PrepareSource.sh
# Prepare the source of ADCTest

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of ADCTest
    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        Source="$WDir"/repos/ADCTest
        getRepo $Repo "$Source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$Source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

    cd repos
    wget -q http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.24.tar.gz
    tar -xf libsndfile-1.0.24.tar.gz
    rm -f libsndfile-1.0.24.tar.gz
    mv -f libsndfile-1.0.24 libsndfile
    sed -i '26d' libsndfile/src/common.c

    wget -q http://www.portaudio.com/archives/pa_stable_v190600_20161030.tgz
    tar -xf pa_stable_v190600_20161030.tgz
    rm -f pa_stable_v190600_20161030.tgz

    wget -q https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.1/wxWidgets-3.1.1.7z
    7za x wxWidgets-3.1.1.7z -owxWidgets
    rm -f wxWidgets-3.1.1.7z

    #TODO: better sed script
    sed -i '38,39d;41,42d' portaudio/build/msvc/portaudio.def
    sed -i '1257,1496d' portaudio/build/msvc/portaudio.vcproj
    sed -i 's/ConfigurationType="2"/ConfigurationType="4"/g' portaudio/build/msvc/portaudio.vcproj
    cd ..

}

function _unix_gui () {

    echo
    echo "Generate the AT GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AT
    mkdir ADCTest_GUI_GNU_FromSource
    cd ADCTest_GUI_GNU_FromSource

    cp -a "$Source" .
    cp -a "$WDir"/repos/libsndfile .
    cp -a "$WDir"/repos/portaudio .
    cp -a "$WDir"/repos/wxWidgets .
    mv ADCTest/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x ADCTest/Project/GNU/GUI/autogen.sh
    #chmod +x MediaInfo/Project/Mac/BR_extension_GUI.sh
    #chmod +x MediaInfo/Project/Mac/Make_MI_dmg.sh

    echo "2: remove what isn’t wanted..."
    cd ADCTest
    rm -fr .git*
    rm -fr debian
    rm -f Project/GNU/adctest.dsc Project/GNU/adctest.spec Project/GNU/PKGBUILD
    rm -fr Project/MSVC2017
    cd ..

    echo "3: Autotools..."
    cd ADCTest/Project/GNU/GUI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/AT
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/ADCTest_GUI${Version}_GNU_FromSource.tar.gz ADCTest_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/ADCTest_GUI${Version}_GNU_FromSource.tar.bz2 ADCTest_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/ADCTest_GUI${Version}_GNU_FromSource.tar.xz ADCTest_GUI_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the AT all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AT
    mkdir adctest_AllInclusive
    cd adctest_AllInclusive

    cp -r "$Source" .

    # Dependencies
    cp -r "$WDir"/repos/libsndfile .
    cp -r "$WDir"/repos/portaudio .
    cp -r "$WDir"/repos/wxWidgets .

    echo "2: remove what isn’t wanted..."
    cd ADCTest
    rm -fr .git*
    rm -fr debian
    rm -f Project/GNU/adctest.dsc Project/GNU/adctest.spec Project/GNU/PKGBUILD
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/AT
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/adctest${Version}_AllInclusive.7z adctest_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the AT directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/AT
    cp -r "$Source" .

    echo "2: remove what isn’t wanted..."
    cd ADCTest
        rm -fr .git*
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/AT
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/adctest${Version}.tar.gz ADCTest)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/adctest${Version}.tar.bz2 ADCTest)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/adctest${Version}.tar.xz ADCTest)

        mkdir ../archives/obs

        cp ../archives/adctest${Version}.tar.xz ../archives/obs/adctest${Version}.orig.tar.xz
        cp ../archives/adctest${Version}.tar.gz ../archives/obs
        cp "$WDir/AT/ADCTest/Project/GNU/adctest.spec" ../archives/obs
        cp "$WDir/AT/ADCTest/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/adctest${Version}.orig.tar.xz ../archives/obs/PKGBUILD
        deb_obs ADCTest "$WDir/AT/ADCTest" "$WDir/archives/obs/adctest${Version}.orig.tar.xz"
    fi

}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr AT
    mkdir AT

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$Source/Project/version.txt")
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "all" ] ; then
        _unix_gui
    fi
    if [ "$Target" = "ai" ] || [ "$Target" = "all" ] ; then
        _all_inclusive
    fi
    if [ "$Target" = "sa" ] || [ "$Target" = "all" ] ; then
        _source_package
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr AT
    fi

}
