# build_release/modules/vm.sh
# VM management module

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function vm_is_running () {
    local URI="$1" Name="$2"

    if [ $# -lt 2 ] ; then 
        return 2
    fi

    # check connectivity with virsh deamon
    if ! virsh -c $URI quit 2>/dev/null ; then
        return 3
    fi

    # return 0 or 1
    test "$(LC_ALL=C virsh -c $URI domstate $Name 2>/dev/null)" == "running"
}

function vm_start() {
    local URI="$1" Name="$2"

    if [ $# -lt 2 ] ; then 
        return 2
    fi

    # check connectivity with virsh deamon
    if ! virsh -c $URI quit 2>/dev/null ; then
        return 3
    fi

    local State="$(LC_ALL=C virsh -c $URI domstate $Name 2>/dev/null)"

    if [ "$State" == "shut off" ] || [ "$State" == "crashed" ] ; then
        LC_ALL=C virsh -c $URI start $Name 2>/dev/null
    elif [ "$State" == "paused" ] ; then
        LC_ALL=C virsh -c $URI resume $Name 2>/dev/null
    elif [ "$State" == "running" ] ; then
        # do nothing
        true
    else
        return 1
    fi

    # return 0 or 1
    vm_is_running $URI $Name
}

function vm_stop () {
    local URI="$1" Name="$2"

    if [ $# -lt 2 ] ; then 
        return 2
    fi

    # check connectivity with virsh deamon
    if ! virsh -c $URI quit 2>/dev/null ; then
        return 3
    fi

    virsh -c $URI shutdown $Name 2>/dev/null
}
