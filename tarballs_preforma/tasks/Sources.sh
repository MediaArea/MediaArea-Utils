# MediaArea-Utils/tarballs_preforma/tasks/Sources.sh
# Generate the tarballs asked by Preforma — sources

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.Sources.run () {

    rm -f src*zip

    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Sources files"
    wget -nd -q -P tmp "https://mediaarea.net/download/source/mediaconch/${MC_version}/mediaconch_${MC_version}_AllInclusive.7z"

    echo "Create Sources package"
    cd tmp
    7za x mediaconch_${MC_version}_AllInclusive.7z > /dev/null

    # Copy license files
    cp ../License*.html mediaconch_AllInclusive/
    cp ../License.*.html mediaconch_AllInclusive/MediaInfoLib
    cp ../License.*.html mediaconch_AllInclusive/ZenLib

    # Keep only MediaArea sources (ZL/MIL/MC)
    rm -fr mediaconch_AllInclusive/zlib
    rm -fr mediaconch_AllInclusive/jansson
    rm -fr mediaconch_AllInclusive/libevent
    rm -fr mediaconch_AllInclusive/libxml2
    rm -fr mediaconch_AllInclusive/libxslt

    # Replace "BSD" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a BSD-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a BSD-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under BSD-2-Clause license conditions" | xargs -0 sed -i "s/This program is freeware under BSD-2-Clause license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    # Replace "zlib" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a zlib-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a zlib-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under zlib license conditions" | xargs -0 sed -i "s/This program is freeware under zlib license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    # Replace repo README.md by MediaConch README.md
    cp -f mediaconch_AllInclusive/MediaConch/README.md mediaconch_AllInclusive/README.md

    rm -f mediaconch_AllInclusive/MediaInfoLib/LICENSE

    cp -f $(b.get bang.working_dir)/readmes/Readme_windows.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src01-$Date.zip mediaconch_AllInclusive

    cd mediaconch_AllInclusive/
    rm -f *bat

    chmod +x ZenLib/Project/GNU/Library/autogen.sh
    chmod +x MediaInfoLib/Project/GNU/Library/autogen.sh
    chmod +x MediaConch/Project/GNU/CLI/autogen.sh
    chmod +x MediaConch/Project/GNU/Server/autogen.sh
    cd ZenLib/Project/GNU/Library
    ./autogen.sh > /dev/null 2>&1
    cd ../../../../MediaInfoLib/Project/GNU/Library
    ./autogen.sh > /dev/null 2>&1
    cd ../../../../MediaConch/Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1
    cd ../../../../MediaConch/Project/GNU/Server
    ./autogen.sh > /dev/null 2>&1
    cd ../../../../
    mv MediaConch/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_compile.sh
    mv MediaConch/Project/GNU/Server/AddThisToRoot_Server_compile.sh Server_compile.sh
    mv MediaConch/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_compile.sh
    chmod +x CLI_compile.sh
    chmod +x Server_compile.sh
    chmod +x GUI_compile.sh
    
    cd ..

    # Mac
    cp -f $(b.get bang.working_dir)/readmes/Readme_mac.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src05-$Date.zip mediaconch_AllInclusive

    cp -f $(b.get bang.working_dir)/readmes/Readme_ubuntu.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src09-$Date.zip mediaconch_AllInclusive

    cp -f $(b.get bang.working_dir)/readmes/Readme_fedora.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src13-$Date.zip mediaconch_AllInclusive

    cp -f $(b.get bang.working_dir)/readmes/Readme_debian.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src17-$Date.zip mediaconch_AllInclusive

    cp -f $(b.get bang.working_dir)/readmes/Readme_opensuse.txt mediaconch_AllInclusive/Read_me.txt
    zip -q -r ../src21-$Date.zip mediaconch_AllInclusive

    cd ..
    rm -fr tmp

}
