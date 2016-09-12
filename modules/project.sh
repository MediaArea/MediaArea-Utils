# modules/project.sh
# Get project informations from cmdline

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function project_get () {
    Project=$(sanitize_arg $(b.opt.get_opt --project))
    if [ "$Project" = "zl" ] || [ "$Project" = "ZL" ] || [ "$Project" = "ZenLib" ]; then
        Project=ZenLib
        Dirname="libzen"
        Repo="https://github.com/MediaArea/ZenLib.git"
    fi
    if [ "$Project" = "mil" ] || [ "$Project" = "MIL" ] || [ "$Project" = "MediaInfoLib" ]; then
        Project=MediaInfoLib
        Dirname="libmediainfo"
        Repo="https://github.com/MediaArea/MediaInfoLib.git"
    fi
    if [ "$Project" = "mi" ] || [ "$Project" = "MI" ] || [ "$Project" = "MediaInfo" ]; then
        Project=MediaInfo
        Dirname="mediainfo"
        Repo="https://github.com/MediaArea/MediaInfo.git"
    fi
    if [ "$Project" = "mc" ] || [ "$Project" = "MC" ] || [ "$Project" = "MediaConch" ]; then
        Project=MediaConch_SourceCode
        Dirname="mediaconch"
        Repo="https://github.com/MediaArea/MediaConch_SourceCode.git"
    fi
    if [ "$Project" = "qc" ] || [ "$Project" = "QC" ] || [ "$Project" = "QCTools" ]; then
        Project=QCTools
        Dirname="qctools"
        Repo="https://github.com/g-maxime/qctools.git"
    fi

    if [ $(b.opt.get_opt --repo) ]; then
        Repo="$(sanitize_arg $(b.opt.get_opt --repo))"
    fi
}

