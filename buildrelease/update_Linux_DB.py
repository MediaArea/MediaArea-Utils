#!/usr/bin/env python
# -*- coding: utf-8 -*-

import MySQLdb
import time
import subprocess
import os
import fnmatch
import glob
import shutil
import sys

print "\n========================================================"
print "update_Linux_DB.py"
print "Copyright (c) MediaArea.net SARL. All Rights Reserved."
print "Use of this source code is governed by a BSD-style"
print "license that can be found in the License.txt file in the"
print "root of the source tree."
print "========================================================\n"

##################################################################
class mysql:

    def __init__(self):
        self.running = True
        try:
            self.sql = MySQLdb.connect(
                    host=config["MySQL_host"],
                    user=config["MySQL_user"],
                    passwd=config["MySQL_passwd"],
                    db=config["MySQL_db"])
        except MySQLdb.Error, e:
            self.running = True
            print "*** MySQL Error %d: %s ***" % (e.args[0], e.args[1])
            print "*** FATAL: quitting ***"
            sys.exit(1)

    def execute(self, query):
        print "---------------- SQL QUERY ----------------"
        print query
        print "-------------------------------------------"
        self.cursor = self.sql.cursor()
        self.cursor.execute(query)
        self.open = True

    def rowcount(self):
        if self.open:
            return self.cursor.rowcount
        else:
            print "*** rowcount: No DB cursor is open! ***"
            return 0

    def fetchone(self):
        if self.open:
            return self.cursor.fetchone()
        else:
            print "*** fetchone: No DB cursor is open! ***"
            return 0

    def fetchall(self):
        if self.open:
            return self.cursor.fetchall()
        else:
            print "*** fetchall: No DB cursor is open! ***"
            return 0

    def closecursor(self):
        if self.open:
            self.sql.commit()
            return self.cursor.close()
        else:
            print "*** close: No DB cursor is open! ***"
            return 0

    def close(self):
        if self.open:
            self.sql.commit()
            return self.cursor.close()
        else:
            print "*** close: No DB cursor is open! ***"
            return 0

##################################################################
def waiting_loop():

    compt = 0
    # Python definitely lack an until statement
    while True:
        compt = compt + 1
        # At first, check every 10mn
        if compt < 10:
            if compt == 1:
                print "Waiting 10mn…"
            else:
                print "All builds aren’t finished yet, waiting another 10mn…"
            time.sleep(600)
        # Past 3h, trigger rebuild if some distros are still in
        # scheduled state, before waiting another 20mn
        else:
            print "All builds aren’t finished yet, trigger rebuilds and waiting 20mn…"
            for dname in Distribs.keys():
                for arch in Distribs[dname]:
                    result = subprocess.check_output("osc results " + MA_Project + " |grep " + dname + " |grep " + arch + " |awk '{print $3}' |sed 's/*//'", shell=True).strip()
                    if result == "scheduled":
                        print "Trigger rebuild for " + dname + arch
                        subprocess.call(["osc", "rebuild", MA_Project, dname, arch])
                        
            time.sleep(1200)
        result = subprocess.check_output("osc results " + MA_Project + " |awk '{print $3}' |sed 's/*//' |grep -v 'excluded\|disabled\|broken\|unresolvable\|failed\|succeeded' |wc -l", shell=True).strip()
        # result will equal 0 when all the distros are build
        if result == "0":
            break

##################################################################
def update_DB():

    # We verify that the DB have all the distributions presents
    # on OBS
    cursor = mysql()
    for dname in Distribs.keys():
        for arch in Distribs[dname]:
            cursor.execute("SELECT * FROM " + table + " WHERE distrib ='" + dname + "' AND arch ='" + arch + "';")
            check = cursor.fetchone()
            # If the couple (dname, arch) isn't already in the DB,
            # we insert it
            if check is None:
                cursor.execute("INSERT INTO " + table + " (distrib, arch) VALUES ('" + dname + "', '" + arch + "');")
    cursor.close()
    
    # Then we update the DB with the results of the build
    cursor = mysql()
    for dname in Distribs.keys():
        for arch in Distribs[dname]:
            result = subprocess.check_output("osc results " + MA_Project + " |grep " + dname + " |grep " + arch + " |awk '{print $3}' |sed 's/*//'", shell=True).strip()
            # First case : if the state is disabled, excluded or
            # unknown
            state = "0"
            if result == "succeeded":
                state = "1"
            if (result == "broken" or result == "unresolvable" or result == "failed"):
                state = "2"
            cursor.execute("UPDATE " + table + " SET state='" + state + "' WHERE distrib ='" + dname + "' AND arch ='" + arch + "';")
            # TODO: if succeeded, update the version field
    cursor.close()

##################################################################
def get_packages_on_OBS():

    cursor = mysql()
    cursor.execute("SELECT * FROM " + table)
    dist_cursor = cursor.fetchall()

    for dist in dist_cursor:

        dname = dist[0]
        arch = dist[1]
        state = dist[2]
        if fnmatch.fnmatch(dname, "Debian*") or \
                fnmatch.fnmatch(dname, "xUbuntu*"):
            pkgtype = "deb"
        if fnmatch.fnmatch(dname, "RHEL*") or \
                fnmatch.fnmatch(dname, "CentOS*") or \
                fnmatch.fnmatch(dname, "Fedora*"):
            pkgtype = "rpm"
            pkginfos[pkgtype]["i586"] = "i686"
        if fnmatch.fnmatch(dname, "SLE*") or \
                fnmatch.fnmatch(dname, "openSUSE*"):
            pkgtype = "rpm"
            pkginfos[pkgtype]["i586"] = "i586"
        #if fnmatch.fnmatch(dname, "Arch*"):
        #    pkgtype = "pkg.tar.xz"

        # state == 1 if build succeeded
        if state == 1:

            # Bin package
            #
            # Fetch the name of the bin package, in order to be
            # able to fetch the package itself
            binname_obs_side = None
            binname_obs_side = subprocess.check_output("osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "| grep 'rpm\|deb' |grep " + binname + pkginfos[pkgtype]["dash"] + version + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'", shell=True).strip()
            # The wanted name for the package, under the forme:
            # name[_|-]version-1[_|.]arch.[deb|rpm]
            binname_final = os.path.join(destination, binname + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
            # If the bin package is build
            # “if not bar == None:” will execute if bar is any
            # kind of zero or empty container, so I check the size
            if len(binname_obs_side) > 1:
                subprocess.call(["osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "/" + binname_obs_side + " > " + binname_final], shell=True)

            # Debug package
            #
            dbgname_obs_side = None
            dbgname_obs_side = subprocess.check_output("osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "| grep 'rpm\|deb' |grep " + dbgname + pkginfos[pkgtype]["debugsuffix"] + pkginfos[pkgtype]["dash"] + version + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'", shell=True).strip()
            dbgname_final = os.path.join(destination, dbgname + pkginfos[pkgtype]["debugsuffix"] + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
            # If the debug package is build
            if len(dbgname_obs_side) > 1:
                subprocess.call(["osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "/" + dbgname_obs_side + " > " + dbgname_final], shell=True)

            # Dev package
            #
            if prjkind == "lib":
                devname_obs_side = None
                devname_obs_side = subprocess.check_output("osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "| grep 'rpm\|deb' |grep " + dbgname + pkginfos[pkgtype]["devsuffix"] + pkginfos[pkgtype]["dash"] + version + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'", shell=True).strip()
                devname_final = os.path.join(destination, dbgname + pkginfos[pkgtype]["devsuffix"] + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
                # If the dev package is build
                if len(devname_obs_side) > 1:
                    subprocess.call(["osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "/" + devname_obs_side + " > " + devname_final], shell=True)

            # GUI package
            #
            if prjkind == "gui":
                guiname_obs_side = None
                guiname_obs_side = subprocess.check_output("osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "| grep 'rpm\|deb' |grep " + binname + "-gui" + pkginfos[pkgtype]["dash"] + version + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'", shell=True).strip()
                guiname_final = os.path.join(destination_gui, binname + "-gui" + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
                # If the GUI package is build
                if len(guiname_obs_side) > 1:
                    subprocess.call(["osc api /build/" + OBS_Project + "/" + dname + "/" + arch + "/" + OBS_Package + "/" + guiname_obs_side + " > " + guiname_final], shell=True)
        
        # state == 2 if build failed
        #elif state == 2:
            #TODO: send a mail

    cursor.close()

##################################################################
# Main

# arguments :
# 1 $OBS_Project (home:MediaArea_net[:snapshots])
# 2 $OBS_Package (ZenLib, MediaInfoLib, …)
# 3 version
# 4 destination for the packages
# [optional: 5 destination for the GUI packages]

OBS_Project = sys.argv[1]
OBS_Package = sys.argv[2]
version = sys.argv[3]
destination = sys.argv[4]

# We get the directory from where the python script is executed
# with os.path.realpath(__file__)
config = {}
execfile(
        os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "update_Linux_DB.conf"),
        config) 
 
MA_Project = OBS_Project + "/" + OBS_Package

if fnmatch.fnmatch(OBS_Package, "ZenLib*"):
    prjkind = "lib"
    binname = "libzen0"
    dbgname = "libzen"
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "ZenLib":
            table = "snapshots_obs_zl"
        elif OBS_Package == "ZenLib_deb6":
            table = "snapshots_obs_zl_deb6"
    else:
        if OBS_Package == "ZenLib":
            table = "releases_obs_zl"
        elif OBS_Package == "ZenLib_deb6":
            table = "releases_obs_zl_deb6"

if OBS_Package == "MediaInfoLib" or fnmatch.fnmatch(OBS_Package, "MediaInfoLib_*"):
    prjkind = "lib"
    binname = "libmediainfo0"
    dbgname = "libmediainfo"
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "MediaInfoLib":
            table = "snapshots_obs_mil"
        elif OBS_Package == "MediaInfoLib_deb6":
            table = "snapshots_obs_mil_deb6"
    else:
        if OBS_Package == "MediaInfoLib":
            table = "releases_obs_mil"
        elif OBS_Package == "MediaInfoLib_deb6":
            table = "releases_obs_mil_deb6"

if fnmatch.fnmatch(OBS_Package, "MediaConch*"):
    prjkind = "gui"
    binname = "mediaconch"
    dbgname = "mediaconch"
    destination_gui = sys.argv[5]
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        table = "snapshots_obs_mc"
    else:
        table = "releases_obs_mc"

# Careful to not catch MediaInfoLib
if OBS_Package == "MediaInfo" or fnmatch.fnmatch(OBS_Package, "MediaInfo_*"):
    prjkind = "gui"
    binname = "mediainfo"
    dbgname = "mediainfo"
    destination_gui = sys.argv[5]
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "MediaInfo":
            table = "snapshots_obs_mi"
        elif OBS_Package == "MediaInfo_deb6":
            table = "snapshots_obs_mi_deb6"
        elif OBS_Package == "MediaInfo_deb7":
            table = "snapshots_obs_mi_deb7"
    else:
        if OBS_Package == "MediaInfo":
            table = "releases_obs_mi"
        elif OBS_Package == "MediaInfo_deb6":
            table = "releases_obs_mi_deb6"
        elif OBS_Package == "MediaInfo_deb7":
            table = "releases_obs_mi_deb7"

# The architecture names (x86_64, i586, …) are imposed by OBS
pkginfos = {
    "deb": {
        "devsuffix": "-dev", "debugsuffix": "-dbg",
        "dash": "_" , "separator": "_",
        "x86_64": "amd64", "i586": "i386"
    },
    "rpm": {
        "devsuffix": "-devel", "debugsuffix": "-debuginfo",
        "dash": "-", "separator": ".",
        "x86_64": "x86_64", "i586": "i686", "ppc64": "ppc64",
        "armv7l": "armv7l"
    },
    # Arch isn’t handled yet
    #"pkg.tar.xz": {
    #    "devsuffix": "", "dash": "", "separator": "",
    #    "x86_64": "", "i586": ""
    #},
}

# TODO: automaticaly build the dictionnary from the active distros
# on OBS
Distribs = {
    #"Arch_Core": ["x86_64", "i586"],
    #"Arch_Extra": ["x86_64", "i586"],
    "CentOS_5": ["x86_64", "i586"],
    "CentOS_6": ["x86_64", "i586"],
    "CentOS_7": ["x86_64"],
    "Debian_6.0": ["x86_64", "i586"],
    "Debian_7.0": ["x86_64", "i586"],
    "Debian_8.0": ["x86_64", "i586"],
    "Fedora_20": ["x86_64", "i586", "armv7l"],
    "Fedora_21": ["x86_64", "i586"],
    "Fedora_22": ["x86_64", "i586"],
    "RHEL_5": ["x86_64", "i586"],
    "RHEL_6": ["x86_64", "i586"],
    "RHEL_7": ["x86_64", "ppc64"],
    "SLE_11": ["x86_64", "i586"],
    "SLE_11_SP1": ["x86_64", "i586"],
    "SLE_11_SP2": ["x86_64", "ppc64", "i586"],
    "SLE_11_SP3": ["x86_64", "i586"],
    "SLE_11_SP4": ["x86_64", "i586"],
    "SLE_12": ["x86_64"],
    "openSUSE_11.4": ["x86_64", "i586"],
    "openSUSE_13.1": ["x86_64", "i586"],
    "openSUSE_13.2": ["x86_64", "i586"],
    "openSUSE_Factory": ["x86_64", "i586"],
    "openSUSE_Factory_ARM": ["armv7l"],
    "openSUSE_Tumbleweed": ["x86_64", "i586"],
    "xUbuntu_12.04": ["x86_64", "i586"],
    "xUbuntu_14.04": ["x86_64", "i586"],
    "xUbuntu_14.10": ["x86_64", "i586"],
    "xUbuntu_15.04": ["x86_64", "i586"],
}

if not os.path.exists(destination):
    os.makedirs(destination)
if prjkind == "gui":
    if not os.path.exists(destination_gui):
        os.makedirs(destination_gui)

waiting_loop()

# At this point, each enabled distros will be either in succeeded
# or failed state. We can update the DB.
update_DB()

get_packages_on_OBS()

#generate_dl_pages()
