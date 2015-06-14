#!/usr/bin/env bang run

# MediaArea-Utils/upgrade_version/UpgradeVersion.sh 
# Upgrade the version number of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

# This script requires : bang.sh, git and sed

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h
    
    b.opt.add_opt --project "The project to modify"
    b.opt.add_alias --project -p

    #b.opt.add_opt --date "Release date"
    #b.opt.add_alias --date -d

    b.opt.add_opt --old "Old release version"
    b.opt.add_alias --old -o
    
    b.opt.add_opt --new "New release version"
    b.opt.add_alias --new -n

    b.opt.add_opt --working-path "Specify working path (otherwise /tmp)"
    b.opt.add_alias --working-path -w

    b.opt.add_opt --repo "Source repository URL"
    b.opt.add_alias --repo -r

    b.opt.add_opt --source-path "Source directory to modify"
    b.opt.add_alias --source-path -s

    # Mandatory arguments
    #b.opt.required_args --project --date --old --new
    b.opt.required_args --project --old --new
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function updateFile () {
    # Arguments :
    # updateFile $Version_old $Version_new "${Source}/${MIL_File}"

    local Search="$1" Replace="$2" File="$3"

    # TODO: handle exception if file not found
    if b.path.file? $File && b.path.readable? $File; then
        $(sed -i "s/${Search}/$Replace/g" $File)
    fi
}

function getRepo () {
    # Arguments :
    # getRepo $Repo $Path

    local Repo="$1" Path="$2"

    cd $Path
    rm -fr $Project
    # TODO: if the repository url is wrong, or no network is available, ask
    # for --source-path and exit
    git clone $Repo
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

        Version_old=$(sanitize_arg $(b.opt.get_opt --old))
        Version_new=$(sanitize_arg $(b.opt.get_opt --new))
        # For the first loop : in the files with version with commas, to
        # avoid the replacement of X,Y,ZZ by X.Y.ZZ we need to specify \.
        # instead of . (because it's a regexp)
        Version_old_escaped=$(b.str.replace_all Version_old '.' '\.')
        # For the second loop : version with commas
        Version_old_comma=$(b.str.replace_all Version_old '.' ',')
        Version_new_comma=$(b.str.replace_all Version_new '.' ',')

        # For the replacement of major/minor/patch : split $Version_new on
        # the .
        OLD_IFS="$IFS"
        IFS="."
        Version_old_array=($Version_old)
        Version_new_array=($Version_new)
        IFS="$OLD_IFS"
        Version_old_major=${Version_old_array[0]}
        Version_old_minor=${Version_old_array[1]}
        Version_old_patch=${Version_old_array[2]}
        Version_new_major=${Version_new_array[0]}
        Version_new_minor=${Version_new_array[1]}
        Version_new_patch=${Version_new_array[2]}

        #Release_date=$(sanitize_arg $(b.opt.get_opt --date))

        # TODO: possibility to run the script from anywhere
        #Script="$(b.get bang.working_dir)/../../${Project}/Release/UpgradeVersion.sh"
        Script="$(b.get bang.working_dir)/../${Project}/UpgradeVersion.sh"

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

        # For lisibility
        echo

        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, so bang can find the
            # corresponding task, then launch it
            . $Script
            b.task.run UpgradeVersion
        else
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in UpgradeVersion.sh's directory to launch it."
            echo "e.g. /path/to/MediaArea-Utils/upgrade_version"
            echo "and the project repository must be in the same directory than MediaArea-Utils"
        fi

        # For lisibility
        echo

        #unset -v Project Release_date Script
        unset -v Project Script
        unset -v Version_old Version_new
        unset -v Version_old_escaped Version_old_comma Version_new_comma
        unset -v Version_old_array Version_new_array 
        unset -v Version_old_major Version_old_minor Version_old_patch
        unset -v Version_new_major Version_new_minor Version_new_patch
    fi
}

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
