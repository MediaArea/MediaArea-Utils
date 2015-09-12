#!/usr/bin/python
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
            self.sql = MySQLdb.connect(host=MySQL_host,
                    user=MySQL_user, passwd=MySQL_passwd, db=MySQL_db)
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
        # At first, check every 20mn
        if compt < 10:
            if compt == 1:
                print "Waiting 20mn…"
            else:
                print "All builds aren’t finished yet, waiting another 20mn…"
            time.sleep(1200)
        # Past 3h, trigger rebuild if some distros are still in
        # scheduled state, before waiting another 20mn
        else:
            print "All builds aren’t finished yet, trigger rebuilds and waiting another 20mn…"
            for dist in Distribs.keys():
                for arch in Distribs[dist]:
                    result = subprocess.check_output("osc results " + OBS_Package + " |grep " + dist + " |grep " + arch + " |awk '{print $3}' |sed 's/*//'", shell=True)
                    if result == "scheduled\n":
                        subprocess.call(["osc", "rebuild", OBS_Package, dname, arch])
            time.sleep(1200)
        result = subprocess.check_output("osc results " + OBS_Package + " 2>&1 |grep -v 'warning: your urllib2' |awk '{print $3}' |sed 's/*//' |grep -v 'excluded\|disabled\|broken\|unresolvable\|failed\|succeeded' |wc -l", shell=True)
        # result will equal "0\n" when all the distros are build
        if result == "0\n":
            break

##################################################################
def update_DB():

    # We verify that the DB have all the distributions presents
    # on OBS
    cursor = mysql()
    for dist in Distribs.keys():
        for arch in Distribs[dist]:
            cursor.execute("SELECT * FROM " + table + " WHERE distrib ='" + dist + "' AND arch ='" + arch + "';")
            check = cursor.fetchone()
            # If the couple (dist, arch) isn't already in the DB,
            # we insert it
            if check is None:
                cursor.execute("INSERT INTO " + table + " (distrib, arch) VALUES ('" + dist + "', '" + arch + "');")
    cursor.close()
    
    # Then we update the DB with the results of the build
    cursor = mysql()
    for dist in Distribs.keys():
        for arch in Distribs[dist]:
            result = subprocess.check_output("osc results " + OBS_Package + " |grep " + dist + " |grep " + arch + " |awk '{print $3}' |sed 's/*//'", shell=True)
            # First case : if the state is disabled, excluded or
            # unknown
            state = "0"
            if result == "succeeded\n":
                state = "1"
            if (result == "broken\n" or result == "unresolvable\n" or result == "failed\n"):
                state = "2"
            cursor.execute("UPDATE " + table + " SET state='" + state + "' WHERE distrib ='" + dist + "' AND arch ='" + arch + "';")
            # TODO: if succeeded, update the version field
    cursor.close()

##################################################################
def get_packages_on_OBS():

    cursor = mysql()
    cursor.execute("SELECT * FROM " + table)
    distribs = cursor.fetchall()
    for dist in distribs:
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
        if fnmatch.fnmatch(dname, "Arch*"):
            pkgtype = "pkg.tar.xz"
        # name[_|-]version-1[_|.]arch.[deb|rpm]
        pkgname_final = os.path.join(destination, pkgname + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
        devname_final = os.path.join(destination, devname + pkginfos[pkgtype]["devsuffix"] + pkginfos[pkgtype]["dash"] + version + "-1" + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] + "." + dname + "." + pkgtype)
        # state == 1 if build succeeded
        if state == 1:
            tmpdir = os.path.join(WDir, dname)
            if not os.path.exists(tmpdir): os.makedirs(tmpdir)
            subprocess.call(["osc", "getbinaries", "--destdir", tmpdir, OBS_Package, dname, arch])
            for file in glob.glob(os.path.join(tmpdir, pkgname) + "*"):
                shutil.move(file, pkgname_final)
            for file in glob.glob(os.path.join(tmpdir, devname) + "*"):
                shutil.move(file, devname_final)
        # state == 2 if build failed
        #elif state == 2:
            #TODO: send a mail
    cursor.close()

##################################################################
# Main

# arguments :
# 1 directory where to work
# 2 destination for the packages
# 2 $OBS_Package
# 3 version

WDir = sys.argv[1]
destination = sys.argv[2]
OBS_Package = sys.argv[3]
version = sys.argv[4]

MySQL_host = "deneb"
MySQL_user = "trololo"
MySQL_passwd = "https://www.youtube.com/watch?v=oavMtUWDBTM"
MySQL_db = "mautils"

if fnmatch.fnmatch(OBS_Package, "*ZenLib*"):
    pkgname = "libzen0"
    devname = "libzen"
if OBS_Package == "home:MediaArea_net/ZenLib":
    table = "releases_obs_zl"
if OBS_Package == "home:MediaArea_net/ZenLib_deb6":
    table = "releases_obs_zl_deb6"
if OBS_Package == "home:MediaArea_net:snapshots/ZenLib":
    table = "snapshots_obs_zl"
if OBS_Package == "home:MediaArea_net:snapshots/ZenLib_deb6":
    table = "snapshots_obs_zl_deb6"

if fnmatch.fnmatch(OBS_Package, "*MediaInfoLib*"):
    pkgname = "libmediainfo0"
    devname = "libmediainfo"
if OBS_Package == "home:MediaArea_net/MediaInfoLib":
    table = "releases_obs_mil"
if OBS_Package == "home:MediaArea_nets/MediaInfoLib_deb6":
    table = "releases_obs_mil_deb6"
if OBS_Package == "home:MediaArea_net:snapshots/MediaInfoLib":
    table = "snapshots_obs_mil"
if OBS_Package == "home:MediaArea_net:snapshots/MediaInfoLib_deb6":
    table = "snapshots_obs_mil_deb6"

# The architecture names (x86_64, i586, …) are imposed by OBS
pkginfos = {
    "deb": {
        "devsuffix": "-dev", "dash": "_" , "separator": "_",
        "x86_64": "amd64", "i586": "i386"
    },
    "rpm": {
        "devsuffix": "-devel", "dash": "-", "separator": ".",
        "x86_64": "x86_64", "i586": "i686", "ppc64": "ppc64",
        "armv7l": "armv7l"
    },
    "pkg.tar.xz": {
        "devsuffix": "", "dash": "", "separator": "",
        "x86_64": "", "i586": ""
    },
}

# TODO: automaticaly build the dictionnary from the active distros
# on OBS
Distribs = {
    "Arch_Core": ["x86_64", "i586"],
    "Arch_Extra": ["x86_64", "i586"],
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

if not os.path.exists(WDir): os.makedirs(WDir)
if not os.path.exists(destination): os.makedirs(destination)

waiting_loop()

# At this point, each enabled distros will be either in succeeded
# or failed state. We can update the DB.
update_DB()

get_packages_on_OBS()

#generate_dl_pages()
