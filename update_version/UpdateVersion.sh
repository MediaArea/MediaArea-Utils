#!/usr/bin/env bang run

# This script requires : bang.sh and sed

### Functions ###

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h
    
    #b.opt.add_opt --date "Release date"
    #b.opt.add_alias --date -d

    b.opt.add_opt --old "Old release version"
    b.opt.add_alias --old -o
    
    b.opt.add_opt --new "New release version"
    b.opt.add_alias --new -n
    
    b.opt.add_opt --project "The project to modify"
    b.opt.add_alias --project -p

    b.opt.add_opt --repo-url "Source repository URL"
    b.opt.add_alias --repo-url -u

    b.opt.add_opt --source-path "Source directory to modify"
    b.opt.add_alias --source-path -s

    # Mandatory arguments
    #b.opt.required_args --old --new --date --project
    b.opt.required_args --old --new --project
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

function getSource () {
    # Arguments :
    # getSource $Path $RepoURL

    local Path="$1" RepoURL="$2"

    cd $Path
    rm -fr $Project
    # TODO: if the repository url is wrong, or no network is available, ask
    # for --source-path and exit
    git clone $RepoURL
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

        #Release_date=$(sanitize_arg $(b.opt.get_opt --date))

        Version_old=$(sanitize_arg $(b.opt.get_opt --old))
        Version_new=$(sanitize_arg $(b.opt.get_opt --new))
        # For the first loop : in the files with version with commas, we
        # want to avoid the replacement of X,Y,ZZ by X.Y.ZZ
        Version_old_dot=${Version_old//'.'/'\.'}
        # For the second loop : version with commas
        Version_old_comma=${Version_old//'.'/','}
        Version_new_comma=${Version_new//'.'/','}

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

        Project=$(sanitize_arg $(b.opt.get_opt --project))

        # TODO: possibility to run the script from anywhere
        Script="$(b.get bang.working_dir)/../../${Project}/Release/Update${Project}.sh"

        # For lisibility
        echo

        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, otherwise bang can't find
            # the corresponding task
            . $Script
            # Launch the task for this project
            b.task.run Update$Project
        else
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in UpdateVersion.sh's directory to launch it."
        fi

        # For lisibility
        echo

        #unset -v Release_date
        unset -v Version_old Version_new
        unset -v Version_old_dot Version_old_comma Version_new_comma
        unset -v Version_old_array Version_new_array 
        unset -v Version_old_major Version_old_minor Version_old_patch
        unset -v Version_new_major Version_new_minor Version_new_patch
    fi
}

### Run! ###

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
