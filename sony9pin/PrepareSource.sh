# sony9pin/Release/PrepareSource.sh
# Prepare the source of sony9pin

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of sony9pin
    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        Source="$WDir"/repos/sony9pin
        getRepo $Repo "$Source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$Source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

}

function _source_package () {

    echo
    echo "Generate the SP directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/SP
    cp -r "$Source" sony9pin

    echo "2: remove what isn’t wanted..."
    rm -fr sony9pin/.git*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/SP
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/sony9pin${Version}.tar.gz sony9pin)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/sony9pin${Version}.tar.bz2 sony9pin)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/sony9pin${Version}.tar.xz sony9pin)

        7za a -t7z -mx=9 -bd ../archives/sony9pin${Version}.7z sony9pin >/dev/null

        mkdir ../archives/obs

        cp ../archives/sony9pin${Version}.tar.gz ../archives/obs/sony9pin${Version}-1.tar.gz
        cp ../archives/sony9pin${Version}.tar.xz ../archives/obs/sony9pin${Version}.orig.tar.xz

        cp "$WDir/SP/sony9pin/Project/GNU/sony9pin.spec" ../archives/obs
        cp "$WDir/SP/sony9pin/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/sony9pin${Version}-1.tar.gz ../archives/obs/PKGBUILD
        deb_obs sony9pin "$WDir/SP/sony9pin" "$WDir/archives/obs/sony9pin${Version}.orig.tar.xz"
    fi
}

function btask.PrepareSource.run () {

    local Source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/sony9pin
    rm -fr "$WDir"/SP
    mkdir "$WDir"/SP

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$Source/Project/version.txt")
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "sa" ] || [ "$Target" = "ai" ] || [ "$Target" = "all" ]; then
        _source_package
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr SP
    fi
}
