# MediaArea-Utils/tarballs_preforma/tasks/Sources.sh
# Generate the tarballs asked by Preforma — sources

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.Sources.run () {

    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Sources files"
    wget -q -P tmp "https://mediaarea.net/download/source/mediaconch/${mc}/mediaconch_${mc}_AllInclusive.7z"

    echo "Create Sources package"
    cd tmp
    7za x mediaconch_${mc}_AllInclusive.7z

    # Copy license files
    cp ../License*.html mediaconch_AllInclusive/
    cp ../License.*.html mediaconch_AllInclusive/MediaInfoLib
    cp ../License.*.html mediaconch_AllInclusive/ZenLib

    # Remove zlib directory
    rm -rf mediaconch_AllInclusive/zlib

    # Replace "BSD" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a BSD-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a BSD-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under BSD-2-Clause license conditions" | xargs -0 sed -i "s/This program is freeware under BSD-2-Clause license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    # Replace "zlib" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a zlib-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a zlib-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under zlib license conditions" | xargs -0 sed -i "s/This program is freeware under zlib license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    zip -q -r ../src01-$Date.zip mediaconch_AllInclusive
    cd ../
    cp src01-$Date.zip src05-$Date.zip
    cp src01-$Date.zip src09-$Date.zip
    cp src01-$Date.zip src13-$Date.zip
    cp src01-$Date.zip src17-$Date.zip
    cp src01-$Date.zip src21-$Date.zip

    rm -rf tmp

}
