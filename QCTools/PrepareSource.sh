# QCTools/Release/PrepareSource.sh
# Prepare the source of QCTools

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    local RepoURL

    if [ $(b.opt.get_opt --repo) ]; then
        RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        RepoURL="https://github.com/g-maxime/qctools.git"
    fi

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of QCTools
    if [ $(b.opt.get_opt --source-path) ]; then
        QC_source="$SDir"
    else
        QC_source="$WDir"/repos/qctools
        getRepo $RepoURL "$QC_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$QC_source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

}

function _source_package () {

    echo
    echo "Generate the QC directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/QC
    cp -r "$QC_source" qctools

    echo "2: remove what isn’t wanted..."
    rm -fr qctools/.git*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/QC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/qctools${Version}.tar.gz qctools)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/qctools${Version}.tar.bz2 qctools)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/qctools${Version}.tar.xz qctools)
    fi
}

function _all_inclusive () {

    echo
    echo "Generate the QC all inclusive tarball::"
    echo "1: copy what is wanted..."

    cd "$WDir"/QC
    mkdir -p ALL/qctools
    cp -r "$QC_source" ALL/qctools/qctools
    cd ALL/qctools

    cp -r qctools/debian .

    git clone "git://source.ffmpeg.org/ffmpeg.git"

    wget http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar -zxvf yasm-1.3.0.tar.gz
    rm yasm-1.3.0.tar.gz
    mv yasm-1.3.0 yasm

    wget http://slackware.uk/sbosrcarch/by-name/multimedia/vlc/Blackmagic_DeckLink_SDK_10.1.4.zip
    unzip Blackmagic_DeckLink_SDK_10.1.4.zip
    rm Blackmagic_DeckLink_SDK_10.1.4.zip
    mv "Blackmagic DeckLink SDK 10.1.4" "Blackmagic DeckLink SDK"

    wget http://downloads.sourceforge.net/project/qwt/qwt/6.1.2/qwt-6.1.2.tar.bz2
    tar jxf qwt-6.1.2.tar.bz2
    rm qwt-6.1.2.tar.bz2
    mv qwt-6.1.2 qwt
    sed -i \
        -e 's/\(^QWT_CONFIG\s\++= QwtDll\)/#\1/g' \
        -e 's/\(^QWT_CONFIG\s\++= QwtSvg\)/#\1/g' \
        -e 's/\(^QWT_CONFIG\s\++= QwtOpenGL\)/#\1/g' \
        -e 's/\(^QWT_CONFIG\s\++= QwtDesigner\)/#\1/g' qwt/qwtconfig.pri

    echo "2: remove what isn’t wanted..."

    rm -fr */.git*

    cd "$WDir"/QC/ALL

    if $MakeArchives; then
        echo "3: compressing..."
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi

        # Generate OBS and MacOS archive
        (GZIP=-9 tar -cz --owner=root --group=root -f ../../archives/qctools${Version}-1.tar.gz qctools)
        # Generate Windows and public AllInclusive archive
        mv qctools qctools_AllInclusive
        pushd qctools_AllInclusive
        git clone "git://github.com/MediaArea/zlib.git"
        rm -fr debian
        # Placeholder for pre-compiled Qt
        mkdir Qt
        popd
        7za a -t7z -mx=9 -bd ../../archives/qctools${Version}_AllInclusive.7z qctools_AllInclusive >/dev/null
    fi

}

function btask.PrepareSource.run () {

    local QC_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/qctools
    rm -fr "$WDir"/QC
    mkdir "$WDir"/QC

    _get_source
    _source_package
    _all_inclusive

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr QC
    fi
}
