#!/usr/bin/env bang run

# MediaArea-Utils/prepare_source/PrepareSource.sh
# Prepare the source of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

# This script requires bang.sh (https://github.com/bangsh/bangsh)
# This script requires the following packages (debian):
#    git tar xz-utils p7zip-full automake libtool doxygen graphviz
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
    b.opt.add_alias --working-path -w

    b.opt.add_opt --repo "Source repository URL"
    b.opt.add_alias --repo -r

    b.opt.add_opt --source-path "Source directory to modify"
    b.opt.add_alias --source-path -s

    b.opt.add_flag --compil-unix "Generate the archive for compilation under Unix"
    b.opt.add_alias --compil-unix -cu

    b.opt.add_flag --compil-windows "Generate the archive for compilation under Windows"
    b.opt.add_alias --compil-windows -cw

    b.opt.add_flag --source-package "Generate the source package"
    b.opt.add_alias --source-package -sp
    
    b.opt.add_flag --all "Prepare all the targets for this project"
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
    # getRepo $Project $RepoURL $Path

    local Project="$1" RepoURL="$2" Path="$3"

    # TODO: if $RepoURL use the git protocol, we must remove the last / if
    # present because the git protocol doesn’t handle //
    # ie. git://github.com/MediaArea>>>//<<<ZenLib fail

    cd $Path
    rm -fr $Project
    # TODO: if $Path isn’t writable, or if no network is available, or
    # if the repository url is wrong, ask for --source-path and exit
    git clone "$RepoURL/$Project"
}

function run () {
    load_options
    b.opt.init "$@"

    # Display help
    if b.opt.has_flag? --help; then
        b.opt.show_usage
        exit
    fi
    
    if b.opt.check_required_args; then

        Project=$(sanitize_arg $(b.opt.get_opt --project))
        if [ "$Project" = "zl" ] || [ "$Project" = "ZL" ]; then
            Project=ZenLib
        fi
        if [ "$Project" = "mil" ] || [ "$Project" = "MIL" ]; then
            Project=MediaInfoLib
        fi
        if [ "$Project" = "mi" ] || [ "$Project" = "MI" ]; then
            Project=MediaInfo
        fi
        if [ "$Project" = "mc" ] || [ "$Project" = "MC" ] || [ "$Project" = "MediaConch" ]; then
            Project=MediaConch_SourceCode
        fi

        Version=""
        if [ $(b.opt.get_opt --version) ]; then
            # We put an _ in $Version, this way if the user doesn't give
            # an --version argument, we don't generate directories and
            # archives with __ (e.g. MediaInfo_GUI__GNU_FromSource)
            Version="_$(sanitize_arg $(b.opt.get_opt --version))"
        fi

        Target="all"
        if b.opt.has_flag? --compil-unix; then
            Target="cu"
        fi
        if b.opt.has_flag? --compil-windows; then
            Target="cw"
        fi
        if b.opt.has_flag? --source-package; then
            Target="sp"
        fi

        # For lisibility
        echo
    
        CleanUp=true
        if b.opt.has_flag? --no-cleanup; then
            CleanUp=false
        fi
        MakeArchives=true
        if b.opt.has_flag? --no-archives; then
            MakeArchives=false
        fi
    
        WPath=/tmp/
        if [ $(b.opt.get_opt --working-path) ]; then
            WPath="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? $WPath && ! b.path.writable? $WPath; then
                echo "The directory $WPath isn't writable : will use /tmp instead."
                echo
                WPath=/tmp/
            else
                # TODO: Handle exception if mkdir fail
                if ! b.path.dir? $WPath ;then
                    mkdir -p $WPath
                fi
            fi
        fi
    
        # TODO: possibility to run the script from anywhere
        #Script="$(b.get bang.working_dir)/../../${Project}/Release/PrepareSource.sh"
        Script="$(b.get bang.working_dir)/../${Project}/PrepareSource.sh"
        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, so bang can find the
            # corresponding task. Then, launch the task.
            . $Script
            b.task.run PrepareSource
        else
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in PrepareSource.sh's directory to launch it."
            echo "e.g. /path/to/MediaArea-Utils/prepare_source"
            echo "and the project repository must be in the same directory than MediaArea-Utils"
        fi

        unset -v Project Version Target CleanUp MakeArchives
        unset -v Script WPath

        # For lisibility
        echo
    fi
}

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
