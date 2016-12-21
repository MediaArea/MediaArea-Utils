#!/usr/bin/env bang run

# MediaArea-Utils/tarballs_preforma/TarballsPreforma.sh
# Generate the tarballs asked by Preforma

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

# This script requires: bang.sh, wget, zip and p7zip

# For A/V (p. 43)
# Windows [exec,src,buildenv]01-AAAA-MM-JJ.zip
# Mac [exec,src,buildenv]05-AAAA-MM-JJ.zip
# Ubuntu [exec,src,buildenv]09-AAAA-MM-JJ.zip
# Fedora [exec,src,buildenv]13-AAAA-MM-JJ.zip
# Debian [exec,src,buildenv]17-AAAA-MM-JJ.zip
# Opensuse [exec,src,buildenv]21-AAAA-MM-JJ.zip

# For text & A/V
# For image & A/V
# For text & image & A/V

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h

    b.opt.add_opt --date "Release date, in AAAA-MM-JJ format (otherwise the current date)"
    b.opt.add_alias --date -d

    b.opt.add_opt --zl-version "ZenLib version"
    b.opt.add_alias --zl-version -zlv
    # Compatibility for Guillaume scripts
    b.opt.add_alias --zl-version --zenlib

    b.opt.add_opt --mil-version "MediaInfoLib version"
    b.opt.add_alias --mil-version -milv
    # Compatibility for Guillaume scripts
    b.opt.add_alias --mil-version --mediainfolib

    b.opt.add_opt --mc-version "MediaConch version"
    b.opt.add_alias --mc-version -mcv
    # Compatibility for Guillaume scripts
    b.opt.add_alias --mc-version --mediaconch

    b.opt.add_opt --working-path "Specify working path (otherwise /tmp)"
    b.opt.add_alias --working-path -wp

    # Mandatory arguments
    b.opt.required_args --zl-version --mil-version --mc-version
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

# Do not display pushd/popd info
pushd () {
    command pushd "$@" > /dev/null
}
popd () {
    command popd "$@" > /dev/null
}

function getLicensesFiles () {

    echo
    echo "Download licenses files..."
    echo

    if ! b.path.file? "License.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.html"
    fi

    if ! b.path.file? "License.GPLv3.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.GPLv3.html"
    fi

    if ! b.path.file? "License.MPLv2.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.MPLv2.html"
    fi

}

function getReadmeFiles () {

    echo
    echo "Download doc files..."
    echo

    if ! b.path.file? "Markdown.pl"; then
        wget -nd -q http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip
        unzip -qj Markdown_1.0.1.zip Markdown_1.0.1/Markdown.pl
        rm Markdown_1.0.1.zip
    fi

    if ! b.path.file? "REST.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/Documentation/REST.md"
        perl Markdown.pl REST.md > REST.html 2>/dev/null
    fi

    if ! b.path.file? "Plugins.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/Documentation/Plugins.md"
        perl Markdown.pl Plugins.md > Plugins.html 2>/dev/null
    fi

    if ! b.path.file? "Deamon.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/Documentation/Daemon.md"
        perl Markdown.pl Daemon.md > Daemon.html 2>/dev/null
    fi

    if ! b.path.file? "Config.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/Documentation/Config.md"
        perl Markdown.pl Config.md > Config.html 2>/dev/null
    fi

    if ! b.path.file? "HowToUse.html"; then
        wget -nd -q "https://raw.githubusercontent.com/MediaArea/MediaConch-Website/master/_documentation/HowToUse.md"

        mkdir img

        for i in $(sed -n 's/.*\(..\/images\/[^\")]*\).*/\1/p' HowToUse.md) ; do
            if ! b.path.file? "img/$(basename $i)" ; then
                wget -nd -q -P img "https://raw.githubusercontent.com/MediaArea/MediaConch-Website/master/_documentation/$i"
            fi
        done

        sed -i '1,6d' HowToUse.md
        sed -i 's/\.\.\/images/img/g' HowToUse.md
        sed -i -e 's/“/\&#8220;/g' -e 's/”/\&#8221;/g' HowToUse.md
        perl Markdown.pl HowToUse.md > HowToUse.html 2>/dev/null
    fi
}

function run () {
    load_options
    b.opt.init "$@"

    # Display help
    if b.opt.has_flag? --help; then
        b.opt.show_usage
        exit 1
    fi

    if b.opt.check_required_args; then

        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        MC_version=$(sanitize_arg $(b.opt.get_opt --mc-version))

        if [ $(b.opt.get_opt --date) ]; then
            Date="$(sanitize_arg $(b.opt.get_opt --date))"
        else
            Date="$(date +%F)"
        fi

        # In case --working-path is not defined
        Working_dir=/tmp
        # In case it is
        if [ $(b.opt.get_opt --working-path) ]; then
            Working_dir="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? "$Working_dir" && ! b.path.writable? "$Working_dir"; then
                echo
                echo "The directory $Working_dir isn’t writable : will use /tmp instead."
                echo
                Working_dir=/tmp
            else
                # TODO: Handle exception if mkdir fail
                if ! b.path.dir? "$Working_dir" ;then
                    mkdir -p "$Working_dir"
                fi
            fi
        fi

        cd "$Working_dir"

        echo

        getLicensesFiles
        getReadmeFiles

        b.task.run Executables
        b.task.run Sources

        b.task.run Buildenv_fedora
        b.task.run Buildenv_debian
        b.task.run Buildenv_ubuntu
        b.task.run Buildenv_opensuse
        b.task.run Buildenv_win
        b.task.run Buildenv_mac

        # Clean up
        rm -fr MediaArea

        unset -v ZL_version MIL_version MC_version
        unset -v Date Working_dir

        echo
        echo

    fi
}

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
