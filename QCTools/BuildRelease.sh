# QCTools/Release/BuildRelease.sh
# Build a release of QCTools

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _windows () {

    local SSHP Build_dir DLPath File

    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    Build_dir="build_$RANDOM"

    cd "$QC_tmp"

    # Windows binaries are kept apart from the others
    mkdir -p "win_binary/qctools/$Sub_dir"

    # Start the VM if needed
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ]; then
        if ! vm_start "$Virsh_uri" "$Win_VM_name" "$Win_IP" "$Win_SSH_port"; then
            MSG="ERROR: unable to start VM"
            print_e "$MSG"
            return 1
        fi
    fi

    # Test connection
    if ! $SSHP "exit"; then
        MSG="ERROR: unable to connect to host"
        print_e "$MSG"
        return 1
    fi
    sleep 3

    # Prepare build directory
    echo "Prepare build directory..."
    $SSHP "Set-Location \"$Win_working_dir\"; if(Test-Path \"$Build_dir\") { Remove-Item -Force -Recurse \"$Build_dir\" }"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\"; New-Item -Type \"directory\" \"$Build_dir\""
    sleep 3

    # Get the tools
    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"
           If (Test-Path \"$Win_working_dir\\MediaArea-Utils-Binaries\\.git\") {
               git clone --quiet \"$Win_working_dir\\MediaArea-Utils-Binaries\" 
           } Else {
              git clone --quiet \"https://github.com/MediaArea/MediaArea-Utils-Binaries.git\"
           }"
    sleep 3

    # Get the sources
    scp -P $Win_SSH_port "prepare_source/archives/qctools_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"
           MediaArea-Utils-Binaries\\Windows\\7-Zip\7z x -y \"qctools_${Version_new}_AllInclusive.7z\""
    sleep 3

    # Build
    echo "Compile QC for Windows..."
    
    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"

           \$env:PATH=\"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Cygwin\\bin;\$env:PATH\"

           # Compile qctools 32 bits
           Remove-Item -Force -Recurse \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"
           Move-Item \"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.6-msvc2015\\5.6\\msvc2015\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"

           Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\BuildAllFromSource\"
           & .\\build.bat 2>&1

           # Make installer
           Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Source\\Install\"
           $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\NSIS\makensis QCTools.nsi

           # Make WithoutInstaller archive
           If (Test-Path \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\Release\\QCTools.exe\") {
              New-Item -Type \"directory\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_i386\"
              Set-Location  \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_i386\"

              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\Release\\QCTools.exe\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\History.txt\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\License.html\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavcodec\\avcodec-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavdevice\\avdevice-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavfilter\\avfilter-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavformat\\avformat-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavutil\\avutil-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libpostproc\\postproc-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libswresample\\swresample-*.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libswscale\\swscale-*.dll\"
              Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\concrt140.dll\"
              Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\msvcp140.dll\"
              Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\vccorlib140.dll\"
              Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x86\Microsoft.VC140.CRT\vcruntime140.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Core.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Gui.dll\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Widgets.dll\"
              New-Item -Type \"directory\" \"imageformats\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\plugins\\imageformats\\qjpeg.dll\" -Destination \"imageformats\"
              New-Item -Type \"directory\" \"platforms\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\plugins\\platforms\\qwindows.dll\" -Destination \"platforms\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_i386_WithoutInstaller.zip *
           }

           # Compile qctools 64 bits
           Remove-Item -Force -Recurse \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"
           Move-Item \"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.6-msvc2015_64\\5.6\\msvc2015_64\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"

           Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\BuildAllFromSource\"
           & .\\build.bat /target x64 2>&1

           # Make WithoutInstaller archive
           If (Test-Path \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\Release\\QCTools.exe\") {
               New-Item -Type \"directory\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_x64\"
               Set-Location  \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_x64\"

               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\Release\\QCTools.exe\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\History.txt\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\License.html\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavcodec\\avcodec-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavdevice\\avdevice-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavfilter\\avfilter-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavformat\\avformat-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libavutil\\avutil-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libpostproc\\postproc-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libswresample\\swresample-*.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\ffmpeg\\libswscale\\swscale-*.dll\"
               Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\concrt140.dll\"
               Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\msvcp140.dll\"
               Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\vccorlib140.dll\"
               Copy-Item \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\redist\x64\Microsoft.VC140.CRT\vcruntime140.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Core.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Gui.dll\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\bin\\Qt5Widgets.dll\"
               New-Item -Type \"directory\" \"imageformats\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\plugins\\imageformats\\qjpeg.dll\" -Destination \"imageformats\"
               New-Item -Type \"directory\" \"platforms\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\Qt\\plugins\\platforms\\qwindows.dll\" -Destination \"platforms\"
               $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_x64_WithoutInstaller.zip *
            }"

    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools"

    File="QCTools_${Version_new}_Windows.exe"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "win_binary/qctools/$Sub_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_i386_WithoutInstaller.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "win_binary/qctools/$Sub_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_x64_WithoutInstaller.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "win_binary/qctools/$Sub_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    # Copy files to the final destination
    scp -r "win_binary/." "$Win_binary_dir"

    # Cleaning
    echo "Cleaning..."
    rm -r "win_binary"

    $SSHP "Set-Location \"$Win_working_dir\"; Remove-Item -Force -Recurse \"$Build_dir\""
    sleep 3
    $SSHP "Set-Location \"$Win_working_dir\"; if(Test-Path \"$Build_dir\") { Remove-Item -Force -Recurse \"$Build_dir\" }"
    sleep 3

    # Stop the VM
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ]; then
        vm_stop "$Virsh_URI" "$Win_VM_name"
    fi

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi

    return 0
}

function _mac () {

    local SSHP

    # SSH prefix
    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"
    Build_dir="build_$RANDOM"

    cd "$QC_tmp"

    # Prepare build directory
    echo "Prepare build directory..."
    $SSHP "cd \"$Mac_working_dir\"
           test ! -e \"$Build_dir\" || rm -fr \"$Build_dir\"
           mkdir \"$Build_dir\""

    # Get the sources
    scp -P $Mac_SSH_port "prepare_source/archives/qctools_${Version_new}-1.tar.gz" "$Mac_SSH_user@$Mac_IP:$Mac_working_dir/$Build_dir/"

    # Compile
    echo "Compile QC for mac..."
    $SSHP "
           cd \"$Mac_working_dir/$Build_dir\"
           export PATH=\"/Users/mymac/Qt/5.3/clang_64/bin:\$PATH\"

           tar xf qctools_${Version_new}-1.tar.gz
           cd qctools/qctools

           ./Project/BuildAllFromSource/build

           test -e Project/QtCreator/QCTools.app/Contents/MacOS/QCTools || exit 1
           cd Project/Mac
           $Key_chain
           ./mkdmg"

    echo "Retreive files"
    DLPath="$Mac_working_dir/$Build_dir/qctools/qctools/Project/Mac"

    File="QCTools.dmg"
    scp -P $Mac_SSH_port "$Mac_SSH_user@$Mac_IP:$DLPath/$File" "$QCB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    # Cleaning
    echo "Cleaning..."
    $SSHP "cd \"$Mac_working_dir\"; rm -fr \"$Build_dir\""

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi

    return 0
}

function _obs () {

    local OBS_package="$OBS_project/QCTools"

    cd "$QC_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/qctools_${Version_new}-1.tar.gz $OBS_package/qctools_${Version_new}-1.tar.gz

    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/qctools.spec $OBS_package
    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/qctools.dsc $OBS_package
    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/PKGBUILD $OBS_package

    update_dsc "$QC_tmp"/$OBS_package qctools_${Version_new}-1.tar.gz qctools.dsc
    update_PKGBUILD "$QC_tmp"/$OBS_package qctools_${Version_new}-1.tar.gz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    _obs
    echo
    echo Launch in background the python script which check
    echo the build results and download the packages...
    echo
    echo The command line is:
    echo python Handle_OBS_results.py $OBS_project QCTools $Version_new "$QCB_dir"
    echo

    # To avoid "os.getcwd() failed: No such file or directory" if
    # $Clean_up is set (ie "$QC_tmp", the current directory, will
    # be deleted)
    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $OBS_project QCTools $Version_new "$QCB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

}

function btask.BuildRelease.run () {

    local Repo UV_flags
    local QCB_dir="$Working_dir"/binary/qctools/$Sub_dir
    local QCS_dir="$Working_dir"/source/qctools/$Sub_dir
    local QC_tmp="$Working_dir"/tmp/qctools/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$QC_tmp"

    mkdir -p "$QCB_dir"
    mkdir -p "$QCS_dir"
    mkdir -p "$QC_tmp"

    cd "$QC_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    if [ $(b.opt.get_opt --repo) ]; then
        Repo="$(sanitize_arg $(b.opt.get_opt --repo))"
    else
        Repo="https://github.com/g-maxime/qctools.git"
    fi

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$QC_tmp"/upgrade_version/qctools
    else
        pushd "$QC_tmp"/upgrade_version
        git clone "$Repo"
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$QC_tmp"/upgrade_version/qctools
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $QC_tmp/upgrade_version/qctools/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p qc -n $Version_new $UV_flags -sp "$QC_tmp"/upgrade_version/qctools

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    find "$QCS_dir" -mindepth 1 -delete
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p qc -v $Version_new -wp "$QC_tmp"/prepare_source -sp "$QC_tmp"/upgrade_version/qctools  $PS_target -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$QC_tmp"/prepare_source/archives/qctools_${Version_new}.* "$QCS_dir"
    fi

    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building QCTools" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$QC_tmp"/prepare_source/archives/qctools_${Version_new}_AllInclusive.7z "$QCS_dir"
    fi

    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building QCTools" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi
    fi

    if $Clean_up; then
        rm -fr "$QC_tmp"
    fi

}
