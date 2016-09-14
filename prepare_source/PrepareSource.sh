#!/usr/bin/env bang run

# MediaArea-Utils/prepare_source/PrepareSource.sh
# Prepare the source of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

# This script requires bang.sh (https://github.com/bangsh/bangsh)
# This script requires the following packages (debian):
#    git ca-certificates tar xz-utils p7zip-full automake libtool
#    doxygen graphviz
# The compilation requires the following packages (debian):
#    g++ make libwxgtk3.0-dev libxml2-dev

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h
    
    b.opt.add_opt --project "The project to work with"
    b.opt.add_alias --project -p

    b.opt.add_opt --version "The version of the project"
    b.opt.add_alias --version -v

    b.opt.add_opt --working-path "Specify working path (otherwise /tmp)"
    b.opt.add_alias --working-path -wp

    b.opt.add_opt --source-path "Source directory to modify"
    b.opt.add_alias --source-path -sp

    b.opt.add_opt --repo "Source repository URL"
    b.opt.add_alias --repo -r

    b.opt.add_opt --git-state "Ask for a specific git state of the current project"
    b.opt.add_alias --git-state -gs

    b.opt.add_opt --mil-gs "Ask for a specific git state for the MIL dependency"
    b.opt.add_opt --zl-gs "Ask for a specific git state for the ZL dependency"

    b.opt.add_flag --compil-unix "Generate the archive for compilation under Unix"
    b.opt.add_alias --compil-unix -cu

    b.opt.add_flag --all-inclusive "Generate the archive for compilation under Windows"
    b.opt.add_alias --all-inclusive -ai

    b.opt.add_flag --source-package "Generate the source package"
    b.opt.add_alias --source-package -sa
    
    b.opt.add_flag --all "Prepare all the targets for a project"
    # Required for the call in _get_source
    b.opt.add_alias --all -all

    b.opt.add_flag --no-cleanup "Don’t erase the temporary directories"
    b.opt.add_alias --no-cleanup -nc

    b.opt.add_flag --no-archives "Don’t create the archives"
    b.opt.add_alias --no-archives --no-archive
    b.opt.add_alias --no-archives -na

    # Mandatory arguments
    b.opt.required_args --project
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function getRepo () {
    # Arguments :
    # getRepo $RepoURL $Path

    local RepoURL="$1" Path="$2"

    # We ensure the parent directories are created, but not the
    # destination directory itself, because git clone will fail if
    # the destination directory already exist
    mkdir -p "$Path"
    rm -fr "$Path"

    if ! git clone "$RepoURL" "$Path"; then
        echo "Error : Unable to clone repository $RepoURL!"
        echo
        echo "Use --source-path to specify a valid and accecible location"
        exit 1
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

        project_get

        Version=""
        if [ $(b.opt.get_opt --version) ]; then
            # We put an _ in $Version, this way if the user doesn’t
            # give an --version argument, we don’t generate
            # directories and archives with __
            # (e.g. MediaInfo_GUI__GNU_FromSource)
            Version="_$(sanitize_arg $(b.opt.get_opt --version))"
        fi

        Target="all"
        if b.opt.has_flag? --compil-unix; then
            Target="cu"
        fi
        if b.opt.has_flag? --all-inclusive; then
            Target="ai"
        fi
        if b.opt.has_flag? --source-package; then
            Target="sa"
        fi

        WDir=/tmp/
        if [ $(b.opt.get_opt --working-path) ]; then
            WDir="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? "$WDir" && ! b.path.writable? "$WDir"; then
                echo
                echo "The directory $WDir isn’t writable : will use /tmp instead."
                echo
                WDir=/tmp/
            else
                if ! b.path.dir? $WDir ;then
                    if ! mkdir -p $WDir ; then
                        echo
                        echo "Unable to create directory $WDir : will use /tmp instead."
                        echo
                        WDir=/tmp/
                    fi
                fi
            fi
        fi

        if [ $(b.opt.get_opt --source-path) ]; then
            SDir="$(sanitize_arg $(b.opt.get_opt --source-path))"
            if ! b.path.dir? "$SDir"; then
                echo
                echo "The directory $SDir doesn’t exist!"
                echo
                exit 1
            fi
        fi

        CleanUp=true
        if b.opt.has_flag? --no-cleanup; then
            CleanUp=false
        fi
        MakeArchives=true
        if b.opt.has_flag? --no-archives; then
            MakeArchives=false
            CleanUp=false
        fi

        # For lisibility
        echo

        Script="$(dirname ${BASH_SOURCE[0]})/../${Project}/PrepareSource.sh"
        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, so bang can find the
            # corresponding task. Then, launch the task.
            . $Script
            b.task.run PrepareSource
        else
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in PrepareSource.sh’s directory to launch it."
            echo "e.g. /path/to/MediaArea-Utils/prepare_source"
            echo "and the project repository must be in the same directory than MediaArea-Utils"
        fi

        unset -v Project Repo Version Target
        unset -v CleanUp MakeArchives
        unset -v Script WDir SDir

        # For lisibility
        echo
    fi
}

# Import globals modules
b.module.append_lookup_dir $(dirname ${BASH_SOURCE[0]})/../modules
b.module.require project

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
