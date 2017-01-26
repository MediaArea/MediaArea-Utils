# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_win.sh
# Generate the tarballs asked by Preforma — Win/Mac build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.Buildenv_win.run () {

    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo
    echo "Generate win build environment..."
    wget -nd -q -P tmp "https://mediaarea.net/download/source/mediaconch/${MC_version}/mediaconch_${MC_version}_AllInclusive.7z"
    cd tmp
    7za x mediaconch_${MC_version}_AllInclusive.7z > /dev/null

    # Keep only not MediaArea sources 
    rm -fr mediaconch_AllInclusive/ZenLib
    rm -fr mediaconch_AllInclusive/MediaInfoLib
    rm -fr mediaconch_AllInclusive/MediaConch
    rm -fr mediaconch_AllInclusive/README.md

    # Add Qt binaries
    git clone --depth 1 "https://github.com/MediaArea/MediaArea-Utils-Binaries.git"
    mv MediaArea-Utils-Binaries/Windows/Qt/Qt5.5-msvc2013 mediaconch_AllInclusive/
    mv MediaArea-Utils-Binaries/Windows/Qt/Qt5.6-msvc2015 mediaconch_AllInclusive/

    echo "Create Windows package (buildenv01)..."
    mv mediaconch_AllInclusive buildenv01
    zip -q -r ../buildenv01-$Date.zip buildenv01

    cd ..
    rm -fr tmp

}
