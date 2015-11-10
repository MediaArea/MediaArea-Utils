# General
EMail=""
EMailCC=""

# Mac
MacIP=""
MacSSHPort=""
MacSSHUser=""
KeyChain=""
if b.opt.has_flag? --snapshot; then
    MacWDir=""
elif [ $(b.opt.get_opt --new) ]; then
    MacWDir=""
fi

# OBS
if b.opt.has_flag? --snapshot; then
    OBS_Project=""
elif [ $(b.opt.get_opt --new) ]; then
    OBS_Project=""
fi

# Windows
WinIP=""
WinSSHPort=""
WinSSHUser=""
