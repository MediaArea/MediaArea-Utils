# QCTools/Release/PrepareSource.sh
# Prepare the source of QCTools

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
        QC_source="$SDir"
    else
        QC_source="$WDir"/repos/qctools
        getRepo $Repo "$QC_source"
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

    git clone --depth 1 --branch n4.4.1 "git://source.ffmpeg.org/ffmpeg.git" ffmpeg

    wget -q https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.bz2
    tar -jxf freetype-2.10.0.tar.bz2
    rm freetype-2.10.0.tar.bz2
    mv freetype-2.10.0 freetype

    wget -q http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar -zxf yasm-1.3.0.tar.gz
    rm yasm-1.3.0.tar.gz
    mv yasm-1.3.0 yasm

    wget -q https://github.com/ElderOrb/qwt/archive/master.zip
    unzip master.zip
    mv qwt-master qwt
    rm master.zip

    # fix ffmpeg configure for static freetype2
    sed -i 's/^enabled libfreetype.*//g' ffmpeg/configure

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
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../../archives/qctools${Version}.orig.tar.xz qctools)

        mkdir ../../archives/obs

        cp ../../archives/qctools${Version}-1.tar.gz ../../archives/obs
        cp ../../archives/qctools${Version}.orig.tar.xz ../../archives/obs
        cp "$QC_source/Project/GNU/qctools.spec" ../../archives/obs
        cp "$QC_source/Project/GNU/PKGBUILD" ../../archives/obs

        update_pkgbuild ../../archives/obs/qctools${Version}-1.tar.gz ../../archives/obs/PKGBUILD
        deb_obs qctools "$WDir/QC/ALL/qctools/qctools" "$WDir/archives/obs/qctools${Version}.orig.tar.xz"

        # Generate Windows and public AllInclusive archive
        mv qctools qctools_AllInclusive
        pushd qctools_AllInclusive
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

    if [ -z "$Version" ] ; then
        Version=_$(cat "$QC_source/Project/version.txt")
    fi

    _source_package
    _all_inclusive

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr QC
    fi
}
