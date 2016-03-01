# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_winmac.sh
# Generate the tarballs asked by Preforma — Win/Mac build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.Buildenv_winmac.run () {

    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo
    echo "Generate win/mac build environment..."
    #wget -nd -q -P tmp "https://mediaarea.net/download/source/mediaconch/${MC_version}/mediaconch_${MC_version}_AllInclusive.7z"
    wget -nd -q -P tmp "http://leprovost.info/fichiers/ma/releases/source/mediaconch/16.02/mediaconch_16.02_AllInclusive.7z"
    cd tmp
    7za x mediaconch_${MC_version}_AllInclusive.7z > /dev/null

    # Keep only not MediaArea sources 
    rm -fr mediaconch_AllInclusive/ZenLib
    rm -fr mediaconch_AllInclusive/MediaInfoLib
    rm -fr mediaconch_AllInclusive/MediaConch

    echo "Create Windows package (buildenv01)..."
    mv mediaconch_AllInclusive buildenv01
    zip -q -r ../buildenv01-$Date.zip buildenv01

    echo "Create Mac package (buildenv05)..."
    mv buildenv01 buildenv05
    rm -f buildenv05/*bat
    zip -q -r ../buildenv05-$Date.zip buildenv05

    cd ..
    rm -fr tmp

}
