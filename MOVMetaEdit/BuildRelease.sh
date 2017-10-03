# MOVMetaEdit/Release/BuildRelease.sh
# Build a release of MOVMetaEdit

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {
    local DLPath File

    cd "$MM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr MOVMetaEdit_CLI*"

    echo
    echo "Compile MM CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MOVMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MOVMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf MOVMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz
           cd MOVMetaEdit_CLI_GNU_FromSource
           ./Project/Mac/BR_extension_CLI.sh
           test -x Project/GNU/CLI/movmetaedit || exit 1
           file Project/GNU/CLI/movmetaedit | grep \"Mach-O universal binary with 2 architectures\" || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh MOVMetaEdit cli $Version_new"

    DLPath="$Mac_working_dir/MOVMetaEdit_CLI_GNU_FromSource/Project/Mac"
    File="MOVMetaEdit_CLI_${Version_new}_Mac.dmg"
    test -e "$MMB_dir"/$File && rm "$MMB_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$MMB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac_gui () {
    local DLPath File

    cd "$MM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr MOVMetaEdit_GUI*"

    echo
    echo "Compile MM GUI for mac..."
    echo

        scp -P $Mac_SSH_port prepare_source/archives/MOVMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MOVMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf MOVMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz
           cd MOVMetaEdit_GUI_GNU_FromSource

           export PATH=$Mac_qt_path/clang_64/bin:\$PATH
           ln -s $Mac_qt_path/clang_64 qt

           ./Project/Mac/BR_extension_GUI.sh
           test -x Project/Qt/MOV\ MetaEdit.app/Contents/MacOS/MOV\ MetaEdit || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh MOV\ MetaEdit gui $Version_new"

    DLPath="$Mac_working_dir/MOVMetaEdit_GUI_GNU_FromSource/Project/Mac"
    File="MOVMetaEdit_GUI_${Version_new}_Mac.dmg"
    test -e "$MMG_dir"/$File && rm "$MMG_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$MMG_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac () {

    local SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"

    _mac_cli
    _mac_gui

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi
}

function _obs () {

    local OBS_package="$OBS_project/MOVMetaEdit"

    cd "$MM_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/obs/* $OBS_package

    cd $OBS_package
    osc addremove *
    osc commit -n
}

function _linux () {

    _obs

    if ! b.opt.has_flag? --jenkins ; then
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
        echo The command line is:
        echo python Handle_OBS_results.py $Filter $OBS_project MOVMetaEdit $Version_new "$MMB_dir" "$MMG_dir"
        echo

        # To avoid "os.getcwd() failed: No such file or directory" if
        # $Clean_up is set (ie "$MM_tmp", the current directory, will
        # be deleted)
        cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
        python Handle_OBS_results.py $Filter $OBS_project MOVMetaEdit $Version_new "$MMB_dir" "$MMG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    else
        echo "#!/bin/bash" > "$WORKSPACE/STAGE"
        echo "python Handle_OBS_results.py $Filter $OBS_project MOVMetaEdit $Version_new \"$MMB_dir\" \"$MMG_dir\"" > "$WORKSPACE/STAGE"
        chmod +x "$WORKSPACE/STAGE"
    fi

}

function btask.BuildRelease.run () {

    local UV_flags
    local MMB_dir="$Working_dir"/binary/movmetaedit/$Sub_dir
    local MMG_dir="$Working_dir"/binary/movmetaedit-gui/$Sub_dir
    local MMS_dir="$Working_dir"/source/movmetaedit/$Sub_dir
    local MM_tmp="$Working_dir"/tmp/movmetaedit/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MM_tmp"

    mkdir -p "$MMB_dir"
    mkdir -p "$MMG_dir"

    mkdir -p "$MMS_dir"
    mkdir -p "$MM_tmp"

    cd "$MM_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$MM_tmp"/upgrade_version/MOVMetaEdit
    else
        pushd "$MM_tmp"/upgrade_version
        git clone "$Repo" MOVMetaEdit
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$MM_tmp"/upgrade_version/MOVMetaEdit
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $MM_tmp/upgrade_version/MOVMetaEdit/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mm -n $Version_new $UV_flags -sp "$MM_tmp"/upgrade_version/MOVMetaEdit

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$MMS_dir" -name 'movmetaedit_*.tar.*' -mindepth 1 -delete
    fi
    #if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
    #    find "$MMB_dir" "$MMG_dir" -name 'MOVMetaEdit_*_GNU_FromSource.*' -mindepth 1 -delete
    #fi
    #if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
    #    find "$MMS_dir" -name 'movmetaedit_*.7z' -mindepth 1 -delete
    #fi

    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mm -v $Version_new -wp "$MM_tmp"/prepare_source -sp "$MM_tmp"/upgrade_version/MOVMetaEdit -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$MM_tmp"/prepare_source/archives/movmetaedit_${Version_new}.tar.* "$MMS_dir"
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building MOVMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$MM_tmp"/prepare_source/archives/MOVMetaEdit_CLI_${Version_new}_GNU_FromSource.* "$MMB_dir"
        mv "$MM_tmp"/prepare_source/archives/MOVMetaEdit_GUI_${Version_new}_GNU_FromSource.* "$MMG_dir"
    fi
    #if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
    #    MSG=
    #    if b.opt.has_flag? --log; then
    #        _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
    #    else
    #        _windows
    #    fi

    #    if [ $? -ne 0 ] ; then
    #        echo -e "$MSG" | mailx -s "[BR Windows] Problem building MOVMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
    #    fi

    #    mv "$MM_tmp"/prepare_source/archives/movmetaedit_${Version_new}.7z "$MMS_dir"
    #fi

    if $Clean_up; then
        rm -fr "$MM_tmp"
    fi

}
