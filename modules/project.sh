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
        Repo="https://github.com/bavc/qctools.git"
    fi
    if [ "$Project" = "da" ] || [ "$Project" = "DA" ] || [ "$Project" = "DVAnalyzer" ]; then
        Project=DVAnalyzer
        Dirname="dvanalyzer"
        Repo="https://github.com/MediaArea/DVAnalyzer.git"
    fi
    if [ "$Project" = "am" ] || [ "$Project" = "AM" ] || [ "$Project" = "AVIMetaEdit" ]; then
        Project=AVIMetaEdit
        Dirname="avimetaedit"
        Repo="https://github.com/MediaArea/AVIMetaEdit.git"
    fi
    if [ "$Project" = "bm" ] || [ "$Project" = "BM" ] || [ "$Project" = "BWFMetaEdit" ]; then
        Project=BWFMetaEdit
        Dirname="bwfmetaedit"
        Repo="https://github.com/MediaArea/BWFMetaEdit.git"
    fi
    if [ "$Project" = "mm" ] || [ "$Project" = "MM" ] || [ "$Project" = "MOVMetaEdit" ]; then
        Project=MOVMetaEdit
        Dirname="movmetaedit"
        Repo="https://github.com/MediaArea/MOVMetaEdit.git"
    fi
    if [ "$Project" = "rc" ] || [ "$Project" = "RC" ] || [ "$Project" = "RAWcooked" ]; then
        Project=RAWcooked
        Dirname="rawcooked"
        Repo="https://github.com/MediaArea/RAWcooked.git"
    fi
    if [ "$Project" = "at" ] || [ "$Project" = "AT" ] || [ "$Project" = "ADCTest" ]; then
        Project=ADCTest
        Dirname="adctest"
        Repo="https://github.com/MediaArea/ADCTest.git"
    fi

    if [ $(b.opt.get_opt --repo) ]; then
        Repo="$(sanitize_arg $(b.opt.get_opt --repo))"
    fi
}

