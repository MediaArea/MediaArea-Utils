# MediaArea-Utils/tarballs_preforma/tasks/Buildenv_winmac.sh
# Generate the tarballs asked by Preforma — Win/Mac build env.

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.Buildenv_mac.run () {
    source $(dirname ${BASH_SOURCE[0]})/../../build_release/Config.sh

    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo
    echo "Generate mac build environment..."
    cd tmp
    mkdir buildenv05
    # Add Qt binaries
    cp -rf $Mac_binaries_dir/{libevent,libxslt,jansson,libxml2,sqlite,Qt} buildenv05

    scp -q -r -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:Qt buildenv05
    sed -i 's/xcrun -find xcrun/xcrun -find xcodebuild/g' buildenv05/Qt/5.3/clang_64/mkspecs/features/mac/default_pre.prf
    sed -i 's/macosx10.8/macosx/g' buildenv05/Qt/5.3/clang_64/mkspecs/qdevice.pri

    echo "Create Mac package (buildenv05)..."
    zip -q -r ../buildenv05-$Date.zip buildenv05

    cd ..
    rm -fr tmp

}
