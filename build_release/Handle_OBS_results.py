#!/usr/bin/env python
# -*- coding: utf-8 -*-

import MySQLdb
import time
import subprocess
import sys
import os
import fnmatch
import glob
import shutil
import time

print "\n========================================================"
print "Handle_OBS_results.py"
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
        # At first, check every 10mn during 3h20
        if compt < 20:
            if compt == 1:
                print "Wait 10mn..."
            else:
                print "All builds aren’t finished yet, wait another 10mn..."
            time.sleep(600)
        # Past 3h30, trigger rebuilds
        else:
            print "All builds aren’t finished yet, trigger rebuild(s) if there are still distribs in scheduled state, and wait 20mn..."
            for dname in Distribs.keys():
                for arch in Distribs[dname]:
                    params = "osc results " + MA_Project \
                           + " |grep " + dname \
                           + " |grep " + arch \
                           + " |awk '{print $3}' |sed 's/*//'"
                    result = subprocess.check_output(params, shell=True).strip()
                    if result == "scheduled":
                        print "Trigger rebuild for " + dname + " (" + arch + ")"
                        subprocess.call(["osc", "rebuild", MA_Project, dname, arch])
                        
            time.sleep(1200)
        params = "osc results " + MA_Project \
               + " |awk '{print $3}' |sed 's/*//' |grep -v 'excluded\|disabled\|broken\|unresolvable\|failed\|succeeded' |wc -l"
        result = subprocess.check_output(params, shell=True).strip()
        # result will equal 0 when all the distros are build
        if result == "0":
            break
        # If we are waiting for more than 9h: (600*20)+(1200*17)
        if compt > 37:
            params = \
                   "echo 'After more than 9 hours, the builds weren’t over. The script has quit whitout downloading anything.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'"
            if len(config["Email_CC"]) > 1:
                params = params + " -c '" + config["Email_CC"] + "'"
            params = params + " " + config["Email_to"]
            subprocess.call(params, shell=True)
            sys.exit(1)

##################################################################
def update_DB():

    # To be sure that the table used to fetch the packages have all
    # the distributions presents on OBS
    cursor = mysql()
    for dname in Distribs.keys():
        for arch in Distribs[dname]:
            cursor.execute("SELECT * FROM `" + table + "` WHERE distrib ='" + dname + "' AND arch ='" + arch + "';")
            check = cursor.fetchone()
            # If the couple (dname, arch) isn't already in the
            # table, we insert it
            if check is None:
                cursor.execute("INSERT INTO `" + table + "` (distrib, arch) VALUES ('" + dname + "', '" + arch + "');")
    cursor.close()
    
    # If this is for a release
    if len(dlpages_table) > 1:
        # To be sure that the table used to update the download
        # pages have all the distributions presents on OBS
        cursor = mysql()
        for dname in Distribs.keys():
            for arch in Distribs[dname]:
                cursor.execute("SELECT * FROM `" + dlpages_table + "` WHERE platform ='" + dname + "' AND arch ='" + arch + "';")
                check = cursor.fetchone()
                # If the couple (dname, arch) isn't already in the
                # table, we insert it
                if check is None:
                    cursor.execute("INSERT INTO `" + dlpages_table + "` (platform, arch) VALUES ('" + dname + "', '" + arch + "');")
        cursor.close()

    # Then we update the table with the results of the build
    cursor = mysql()
    for dname in Distribs.keys():
        for arch in Distribs[dname]:
            # We take "grep 'dname '" instead of "grep dname"
            # because the name of a distrib can be included in the
            # names of another distribs (ie SLE_11 and SLE_11_SPx)
            params = "osc results " + MA_Project \
                   + " |grep '" + dname + " '"\
                   + " |grep " + arch \
                   + " |awk '{print $3}' |sed 's/*//'"
            result = subprocess.check_output(params, shell=True).strip()
            # First case : if the state is disabled, excluded or
            # unknown
            state = "0"
            if result == "succeeded":
                state = "1"
            if (result == "broken" or result == "unresolvable" or result == "failed"):
                state = "2"
            cursor.execute("UPDATE `" + table + "` SET state='" + state + "' WHERE distrib ='" + dname + "' AND arch ='" + arch + "';")
    cursor.close()

##################################################################
def get_packages_on_OBS():

    cursor = mysql()
    cursor.execute("SELECT * FROM `" + table + "`")
    dist_cursor = cursor.fetchall()

    for dist in dist_cursor:

        dname = dist[0]
        arch = dist[1]
        state = dist[2]

        # state == 1 if build succeeded
        if state == 1:

            print
            print "API commands for " + dname + " (" + arch + ")"
            print

            # Initialization depending on the distrib’s family
            revision = ""
            if fnmatch.fnmatch(dname, "Debian*") or \
                    fnmatch.fnmatch(dname, "xUbuntu*"):
                pkgtype = "deb"
                revision = "-1"
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

            ###############
            # Bin package #
            ###############

            # bin = the library package in case of a library, or
            # the cli package otherwise

            # The wanted name for the package, under the form:
            # name[_|-]version[-1][_|.]arch.[deb|rpm]
            binname_wanted = binname \
                    + pkginfos[pkgtype]["dash"] + version \
                    + revision \
                    + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] \
                    + "." + dname \
                    + "." + pkgtype
            binname_final = os.path.join(destination, binname_wanted)

            binname_obs_side = "0"
            # Fetch the name of the package on OBS
            # We take “ deb" ” to avoid the *.debian.txz files
            params = "osc api /build/" + OBS_Project \
                   + "/" + dname \
                   + "/" + arch \
                   + "/" + OBS_Package \
                   + " |grep 'rpm\"\|deb\"'" \
                   + " |grep " + binname + pkginfos[pkgtype]["dash"] + version \
                   + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
            print "Name of the bin package on OBS:"
            print params
            binname_obs_side = subprocess.check_output(params, shell=True).strip()

            # If the bin package is build
            if len(binname_obs_side) > 1:
                params_getpackage = \
                        "osc api /build/" + OBS_Project \
                        + "/" + dname \
                        + "/" + arch \
                        + "/" + OBS_Package \
                        + "/" + binname_obs_side \
                        + " > " + binname_final
                print "Command to fetch the bin package:"
                print params_getpackage
                print
                subprocess.call(params_getpackage, shell=True)

                # This is potentially a spam tank, but I leave the
                # mails here because:
                # 1. it allows to have the command that have
                # failed = more convenient to understand the issue
                # 2. because of the multiple runs for the
                # multiple OBS repos (Project_debX), the final test
                # can miss some download errors.

                # If the bin package is build, but hasn’t been
                # downloaded for some raison.
                if not os.path.isfile(binname_final):
                    params = \
                           "echo '" + dname + " (" + arch + "): the bin package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                           + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                           + " " + config["Email_to"]
                    subprocess.call(params, shell=True)

            #################
            # Debug package #
            #################

            # name-[dbg|debuginfo][_|-]version[-1][_|.]arch.[deb|rpm]
            dbgname_wanted = dbgname \
                    + pkginfos[pkgtype]["debugsuffix"] \
                    + pkginfos[pkgtype]["dash"] + version \
                    + revision \
                    + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] \
                    + "." + dname \
                    + "." + pkgtype
            dbgname_final = os.path.join(destination, dbgname_wanted)

            dbgname_obs_side = "0"
            # Fetch the name of the package on OBS
            params = "osc api /build/" + OBS_Project \
                   + "/" + dname \
                   + "/" + arch \
                   + "/" + OBS_Package \
                   + " |grep 'rpm\"\|deb\"'" \
                   + " |grep " + dbgname + pkginfos[pkgtype]["debugsuffix"] + pkginfos[pkgtype]["dash"] + version \
                   + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
            print "Name of the debug package on OBS:"
            print params
            dbgname_obs_side = subprocess.check_output(params, shell=True).strip()

            # If the debug package is build
            if len(dbgname_obs_side) > 1:
                params_getpackage = \
                        "osc api /build/" + OBS_Project \
                        + "/" + dname \
                        + "/" + arch \
                        + "/" + OBS_Package \
                        + "/" + dbgname_obs_side \
                        + " > " + dbgname_final
                print "Command to fetch the debug package:"
                print params_getpackage
                print
                subprocess.call(params_getpackage, shell=True)

                # If the debug package is build, but hasn’t been
                # downloaded for some raison.
                if not os.path.isfile(dbgname_final):
                    params = \
                           "echo '" + dname + " (" + arch + "): the debug package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                           + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                           + " " + config["Email_to"]
                    subprocess.call(params, shell=True)
            else:
                print

            ###############
            # Dev package #
            ###############

            if prjkind == "lib":

                # name-dev[el][_|-]version[-1][_|.]arch.[deb|rpm]
                devname_wanted = dbgname \
                        + pkginfos[pkgtype]["devsuffix"] \
                        + pkginfos[pkgtype]["dash"] + version \
                        + revision \
                        + pkginfos[pkgtype]["separator"] \
                        + pkginfos[pkgtype][arch] \
                        + "." + dname \
                        + "." + pkgtype
                devname_final = os.path.join(destination, devname_wanted)

                devname_obs_side = "0"
                # Fetch the name of the package on OBS
                params = "osc api /build/" + OBS_Project \
                       + "/" + dname \
                       + "/" + arch \
                       + "/" + OBS_Package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + dbgname + pkginfos[pkgtype]["devsuffix"] + pkginfos[pkgtype]["dash"] + version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the dev package on OBS:"
                print params
                print
                devname_obs_side = subprocess.check_output(params, shell=True).strip()

                # If the dev package is build
                if len(devname_obs_side) > 1:
                    params_getpackage = \
                            "osc api /build/" + OBS_Project \
                            + "/" + dname \
                            + "/" + arch \
                            + "/" + OBS_Package \
                            + "/" + devname_obs_side \
                            + " > " + devname_final
                    print "Command to fetch the dev package:"
                    print params_getpackage
                    print
                    subprocess.call(params_getpackage, shell=True)

                    # If the debug package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(devname_final):
                        params = \
                               "echo '" + dname + " (" + arch + "): the dev package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                               + " " + config["Email_to"]
                        subprocess.call(params, shell=True)

            ###############
            # Doc package #
            ###############

                # name-doc[_|-]version[-1][_|.]arch.[deb|rpm]
                docname_wanted = dbgname + "-doc" \
                        + pkginfos[pkgtype]["dash"] + version \
                        + revision \
                        + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] \
                        + "." + dname \
                        + "." + pkgtype
                docname_final = os.path.join(destination, docname_wanted)
    
                docname_obs_side = "0"
                # Fetch the name of the package on OBS
                params = "osc api /build/" + OBS_Project \
                       + "/" + dname \
                       + "/" + arch \
                       + "/" + OBS_Package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep doc |grep -v src |awk -F '\"' '{print $2}'"
                print "Name of the doc package on OBS:"
                print params
                docname_obs_side = subprocess.check_output(params, shell=True).strip()
    
                # If the doc package is build
                if len(docname_obs_side) > 1:
                    params_getpackage = \
                            "osc api /build/" + OBS_Project \
                            + "/" + dname \
                            + "/" + arch \
                            + "/" + OBS_Package \
                            + "/" + docname_obs_side \
                            + " > " + docname_final
                    print "Command to fetch the doc package:"
                    print params_getpackage
                    print
                    subprocess.call(params_getpackage, shell=True)
    
                    # If the doc package is build, but hasn’t been
                    # downloaded for some raison.
                    if not os.path.isfile(docname_final):
                        params = \
                               "echo '" + dname + " (" + arch + "): the doc package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                               + " " + config["Email_to"]
                        subprocess.call(params, shell=True)

            ###############
            # GUI package #
            ###############

            if prjkind == "gui":

                # name-gui[_|-]version[-1][_|.]arch.[deb|rpm]
                guiname_wanted = binname + "-gui" \
                        + pkginfos[pkgtype]["dash"] + version \
                        + revision \
                        + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] \
                        + "." + dname \
                        + "." + pkgtype
                guiname_final = os.path.join(destination_gui, guiname_wanted)

                guiname_obs_side = "0"
                # Fetch the name of the package on OBS
                params = "osc api /build/" + OBS_Project \
                       + "/" + dname \
                       + "/" + arch \
                       + "/" + OBS_Package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + binname + "-gui" + pkginfos[pkgtype]["dash"] + version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the gui package on OBS:"
                print params
                guiname_obs_side = subprocess.check_output(params, shell=True).strip()

                # If the gui package is build
                if len(guiname_obs_side) > 1:
                    params_getpackage = \
                            "osc api /build/" + OBS_Project \
                            + "/" + dname \
                            + "/" + arch \
                            + "/" + OBS_Package \
                            + "/" + guiname_obs_side \
                            + " > " + guiname_final
                    print "Command to fetch the gui package:"
                    print params_getpackage
                    print
                    subprocess.call(params_getpackage, shell=True)

                    # If the gui package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(guiname_final):
                        params = \
                               "echo '" + dname + " (" + arch + "): the gui package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                               + " " + config["Email_to"]
                        subprocess.call(params, shell=True)

            ##################
            # Server package #
            ##################

            if binname == "mediaconch":

                # name-server[_|-]version[-1][_|.]arch.[deb|rpm]
                servername_wanted = binname + "-server" \
                        + pkginfos[pkgtype]["dash"] + version \
                        + revision \
                        + pkginfos[pkgtype]["separator"] + pkginfos[pkgtype][arch] \
                        + "." + dname \
                        + "." + pkgtype
                servername_final = os.path.join(destination_server, servername_wanted)

                servername_obs_side = "0"
                # Fetch the name of the package on OBS
                params = "osc api /build/" + OBS_Project \
                       + "/" + dname \
                       + "/" + arch \
                       + "/" + OBS_Package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + binname + "-server" + pkginfos[pkgtype]["dash"] + version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the server package on OBS:"
                print params
                servername_obs_side = subprocess.check_output(params, shell=True).strip()

                # If the server package is build
                if len(servername_obs_side) > 1:
                    params_getpackage = \
                            "osc api /build/" + OBS_Project \
                            + "/" + dname \
                            + "/" + arch \
                            + "/" + OBS_Package \
                            + "/" + servername_obs_side \
                            + " > " + servername_final
                    print "Command to fetch the server package:"
                    print params_getpackage
                    print
                    subprocess.call(params_getpackage, shell=True)

                    # If the server package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(servername_final):
                        params = \
                               "echo '" + dname + " (" + arch + "): the server package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                               + " " + config["Email_to"]
                        subprocess.call(params, shell=True)

            ###########################
            # Put the filenames in DB #
            ###########################

            # If we run for a release
            if len(dlpages_table) > 1:

                # For the libs
                if prjkind == "lib":
                    cursor.execute("UPDATE `" + dlpages_table + "` SET"\
                            + " version = '" + version + "'," \
                            + " libname = '" + binname_wanted + "'," \
                            + " libnamedbg = '" + dbgname_wanted + "'," \
                            + " libnamedev = '" + devname_wanted + "'" \
                            + " WHERE platform = '" + dname + "'" \
                            + " AND arch = '" + arch + "';")

                # For MC
                if binname == "mediaconch":
                    cursor.execute("UPDATE `" + dlpages_table + "` SET"\
                            + " version = '" + version + "'," \
                            + " cliname = '" + binname_wanted + "'," \
                            + " clinamedbg = '" + dbgname_wanted + "'," \
                            + " servername = '" + servername_wanted + "'," \
                            + " guiname = '" + guiname_wanted + "'" \
                            + " WHERE platform = '" + dname + "'" \
                            + " AND arch = '" + arch + "';")

                # For MI
                if binname == "mediainfo":
                    cursor.execute("UPDATE `" + dlpages_table + "` SET"\
                            + " version = '" + version + "'," \
                            + " cliname = '" + binname_wanted + "'," \
                            + " clinamedbg = '" + dbgname_wanted + "'," \
                            + " guiname = '" + guiname_wanted + "'" \
                            + " WHERE platform = '" + dname + "'" \
                            + " AND arch = '" + arch + "';")


            print "-----------------------"

    cursor.close()

##################################################################
def verify_states_and_files():

    cursor = mysql()
    cursor.execute("SELECT * FROM `" + table + "`")
    dist_cursor = cursor.fetchall()
    cursor.close()

    nb_succeeded = 0
    dists_failed = []

    for dist in dist_cursor:

        dname = dist[0]
        arch = dist[1]
        state = dist[2]

        # state == 1 if build succeeded
        if state == 1:
            nb_succeeded = nb_succeeded + 1

        # state == 2 if build failed
        if state == 2:
            dists_failed.append(dist)

    print "(In case the mails can’t be send:)"
    print "succeeded: " + str(nb_succeeded) \

    ################
    # Bin packages #
    ################

    # Careful: if multiple instances run at the same time (debX)
    # and one of them doesn’t download its packages, the problem
    # may not be detected. Because the packages downloaded by other
    # instances will be counted in nb_bin.

    nb_bin = 0
    params = "ls " + destination + "/" + binname + "*" + version + "*" \
           + " |grep 'rpm\|deb'" \
           + " |grep -v 'dbg\|debug'" \
           + " |wc -l"
    result = subprocess.check_output(params, shell=True).strip()
    nb_bin = int(result)

    # It’s not a good idea to put it before the previous line, as
    # in some case result is an int, and other time it’s a str…
    print "bin: " + str(nb_bin)

    if nb_bin < nb_succeeded:
        params = \
               "echo 'The number of downloaded bin packages is lower than the number of succeeded bin packages on OBS:\n" \
               + str(nb_succeeded) + " succeeded and " + str(nb_bin) + " downloaded.'" \
               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
               + " " + config["Email_to"]
        subprocess.call(params, shell=True)

    ##################
    # Debug packages #
    ##################

    nb_dbg = 0
    params = "ls " + destination + "/" + dbgname + "*" \
           + " |grep 'rpm\|deb'" \
           + " |grep 'dbg\|debug'" \
           + " |wc -l"
    result = subprocess.check_output(params, shell=True).strip()
    nb_dbg = int(result)

    print "dbg: " + str(nb_dbg)

    # Debug packages aren’t perfectly handled on OBS
    #if nb_dbg < nb_succeeded:
    #    params = \
    #           "echo 'The number of downloaded debug packages is lower than the number of succeeded debug packages on OBS:\n" \
    #           + str(nb_succeeded) + " succeeded and " + str(nb_dbg) + " downloaded.'" \
    #           + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'"
    #           + " " + config["Email_to"]
    #    subprocess.call(params, shell=True)

    ################
    # Dev packages #
    ################

    if prjkind == "lib":
        nb_dev = 0
        params = "ls " + destination + "/" + dbgname + "*" \
               + " |grep 'rpm\|deb'" \
               + " |grep 'dev\|devel'" \
               + " |wc -l"
        result = subprocess.check_output(params, shell=True).strip()
        nb_dev = int(result)
        
        print "dev: " + str(nb_dev)

        if nb_dev < nb_succeeded:
            params = \
                   "echo 'The number of downloaded dev packages is lower than the number of succeeded dev packages on OBS:\n" \
                   + str(nb_succeeded) + " succeeded and " + str(nb_dev) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)

        ################
        # Doc packages #
        ################
    
        nb_doc = 0
        params = "ls " + destination + "/" + dbgname + "-doc*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        result = subprocess.check_output(params, shell=True).strip()
        nb_doc = int(result)

        print "doc: " + str(nb_doc)

        # Doc packages aren’t generated by OBS on debX repo
        if nb_doc < nb_succeeded and not fnmatch.fnmatch(OBS_Package, "*_deb?"):
            params = \
                   "echo 'The number of downloaded doc packages is lower than the number of succeeded doc packages on OBS:\n" \
                   + str(nb_succeeded) + " succeeded and " + str(nb_doc) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)

    ###################
    # Server packages #
    ###################

    if binname == "mediaconch":
        nb_server = 0
        params = "ls " + destination_server + "/" + binname + "-server" + "?" + version + "*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        result = subprocess.check_output(params, shell=True).strip()
        nb_server = int(result)
        
        print "server: " + str(nb_server)

        if nb_server < nb_succeeded:
            params = \
                   "echo 'The number of downloaded server packages is lower than the number of succeeded server packages on OBS:\n" \
                   + str(nb_succeeded) + " succeeded and " + str(nb_server) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)

    ################
    # GUI packages #
    ################

    if prjkind == "gui":
        nb_gui = 0
        params = "ls " + destination_gui + "/" + binname + "-gui" + "?" + version + "*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        result = subprocess.check_output(params, shell=True).strip()
        nb_gui = int(result)
        
        print "gui: " + str(nb_gui)

        if nb_gui < nb_succeeded:
            params = \
                   "echo 'The number of downloaded gui packages is lower than the number of succeeded gui packages on OBS:\n" \
                   + str(nb_succeeded) + " succeeded and " + str(nb_gui) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)

    ###################
    # Failed packages #
    ###################

    if len(dists_failed) > 0:

        fail_list = ""
        for dist in dists_failed:
            fail_list = fail_list + "* " + str(dist[0]) + " (" + str(dist[1]) + ")\n"

        print "\nFailed:\n" + fail_list

        params = \
               "echo 'OBS project: " + OBS_Project + "\n" \
               + "OBS package: " + OBS_Package + "\n" \
               + "Version: " + version + "\n\n" \
               + "The build have fail on OBS for:\n" + fail_list + "'" \
               + " |mailx -s '[BR lin] Problem with " + OBS_Package + "'" \
               + " " + config["Email_to"]
        subprocess.call(params, shell=True)

    # Confirmation mails

    q,s = divmod(time.time()-time_start, 60)
    h,m = divmod(q, 60)
    if h < 10:
        time_total = "0" + str("%d" % h)
    else:
        time_total = str("%d" % h)
    time_total = time_total + ":"
    if m < 10:
        time_total = time_total + "0" + str("%d" % m)
    else:
        time_total = time_total + str("%d" % m)
    time_total = time_total + ":"
    if s < 10:
        time_total = time_total + "0" + str("%d" % s)
    else:
        time_total = time_total + str("%d" % s)

    print "\nHandle_OBS_results.py has run during: " + time_total

    # Don’t send a confirmation mail for the debX repo
    if prjkind == "lib" and not fnmatch.fnmatch(OBS_Package, "*_deb?"):
        # We use >= and not =, because there may be other repos
        # which have ran into the same directory (Project_debX).
        if (len(dists_failed) == 0) and (nb_bin >= nb_succeeded) and (nb_dev >= nb_succeeded) and (nb_doc >= nb_succeeded):
            params = \
                   "echo 'OBS project: " + OBS_Project + "\n" \
                    + "OBS package: " + OBS_Package + "\n" \
                    + "Version: " + version + "\n\n" \
                   + "SUCCESS\n\n" \
                   + "* " + str(nb_succeeded) + " builds succeeded;\n" \
                   + "* " + str(nb_bin) + " bin (" + binname + ") packages downloaded;\n" \
                   + "* " + str(nb_dev) + " dev packages downloaded;\n" \
                   + "* " + str(nb_dbg) + " debug packages downloaded (debug packages aren’t perfectly handled on OBS);\n" \
                   + "* " + str(nb_doc) + " doc packages downloaded.\n\n" \
                   + "Handle_OBS_results.py has run during: " + time_total + "'" \
                   + " |mailx -s '[BR lin] OK for " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)
    
    if prjkind == "gui" and not fnmatch.fnmatch(OBS_Package, "*_deb?"):
        if (len(dists_failed) == 0) and (nb_bin >= nb_succeeded) and (nb_gui >= nb_succeeded):
            params = \
                   "echo 'OBS project: " + OBS_Project + "\n" \
                    + "OBS package: " + OBS_Package + "\n" \
                    + "Version: " + version + "\n\n" \
                   + "SUCCESS\n\n" \
                   + "* " + str(nb_succeeded) + " builds succeeded;\n" \
                   + "* " + str(nb_bin) + " bin (CLI) packages downloaded;\n" \
                   + "* " + str(nb_dbg) + " debug packages downloaded (debug packages aren’t perfectly handled on OBS);\n" \
                   + "* " + str(nb_gui) + " gui packages downloaded.\n\n" \
                   + "Handle_OBS_results.py has run during: " + time_total + "'" \
                   + " |mailx -s '[BR lin] OK for " + OBS_Package + "'" \
                   + " " + config["Email_to"]
            subprocess.call(params, shell=True)

##################################################################
# Main

time_start = time.time()

# arguments :
# 1 $OBS_Project (home:MediaArea_net[:snapshots])
# 2 $OBS_Package (ZenLib, MediaInfoLib, …)
# 3 version
# 4 destination for the packages
# For MC: 5 destination for the server packages and 6 for the GUI
# For MI: 5 destination for the GUI packages

#
# Handle the variables
#

OBS_Project = sys.argv[1]
OBS_Package = sys.argv[2]
version = sys.argv[3]
destination = sys.argv[4]
# The directory from where the python script is executed
script_emplacement = os.path.dirname(os.path.realpath(__file__))

config = {}
execfile( os.path.join( script_emplacement, "Handle_OBS_results.conf"), config)
 
MA_Project = OBS_Project + "/" + OBS_Package
dlpages_table = "0"

if fnmatch.fnmatch(OBS_Package, "ZenLib*"):
    prjkind = "lib"
    binname = "libzen0"
    dbgname = "libzen"
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "ZenLib":
            table = "snapshots_obs_zl"
        elif OBS_Package == "ZenLib_deb6":
            table = "snapshots_obs_zl_deb6"
        elif OBS_Package == "ZenLib_deb9":
            table = "snapshots_obs_zl_deb9"
            binname = "libzen0v5"
    else:
        dlpages_table = "releases_dlpages_zl"
        if OBS_Package == "ZenLib":
            table = "releases_obs_zl"
        elif OBS_Package == "ZenLib_deb6":
            table = "releases_obs_zl_deb6"
        elif OBS_Package == "ZenLib_deb9":
            table = "releases_obs_zl_deb9"
            binname = "libzen0v5"

if OBS_Package == "MediaInfoLib" or fnmatch.fnmatch(OBS_Package, "MediaInfoLib_*"):
    prjkind = "lib"
    binname = "libmediainfo0"
    dbgname = "libmediainfo"
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "MediaInfoLib":
            table = "snapshots_obs_mil"
        elif OBS_Package == "MediaInfoLib_deb6":
            table = "snapshots_obs_mil_deb6"
        elif OBS_Package == "MediaInfoLib_deb9":
            table = "snapshots_obs_mil_deb9"
            binname = "libmediainfo0v5"
        elif OBS_Package == "MediaInfoLib_u12.04":
            table = "snapshots_obs_mil_u12.04"
    else:
        dlpages_table = "releases_dlpages_mil"
        if OBS_Package == "MediaInfoLib":
            table = "releases_obs_mil"
        elif OBS_Package == "MediaInfoLib_deb6":
            table = "releases_obs_mil_deb6"
        elif OBS_Package == "MediaInfoLib_deb9":
            table = "releases_obs_mil_deb9"
            binname = "libmediainfo0v5"
        elif OBS_Package == "MediaInfoLib_u12.04":
            table = "releases_obs_mil_u12.04"

if fnmatch.fnmatch(OBS_Package, "MediaConch*"):
    prjkind = "gui"
    binname = "mediaconch"
    dbgname = "mediaconch"
    destination_server = sys.argv[5]
    destination_gui = sys.argv[6]
    if fnmatch.fnmatch(OBS_Project, "*:snapshots"):
        if OBS_Package == "MediaConch":
            table = "snapshots_obs_mc"
        if OBS_Package == "MediaConch_deb9":
            table = "snapshots_obs_mc_deb9"
    else:
        dlpages_table = "releases_dlpages_mc"
        if OBS_Package == "MediaConch":
            table = "releases_obs_mc"
        if OBS_Package == "MediaConch_deb9":
            table = "releases_obs_mc_deb9"

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
        elif OBS_Package == "MediaInfo_deb9":
            table = "snapshots_obs_mi_deb9"
    else:
        dlpages_table = "releases_dlpages_mi"
        if OBS_Package == "MediaInfo":
            table = "releases_obs_mi"
        elif OBS_Package == "MediaInfo_deb6":
            table = "releases_obs_mi_deb6"
        elif OBS_Package == "MediaInfo_deb7":
            table = "releases_obs_mi_deb7"
        elif OBS_Package == "MediaInfo_deb9":
            table = "releases_obs_mi_deb9"

# The architecture names (x86_64, i586, …) are imposed by OBS.
#
# If an architecture is actived on OBS, but not listed here, 
# pkginfos[pkgtype][arch] will raise a KeyError.
#
# In the declaration of a dictionary, you MUST put spaces after the
# commas, if not python can behave strangely.
#
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
        "aarch64": "aarch64", "armv7l": "armv7l",
        "armv6l": "armv6l"
    }
    #},
    # Arch isn’t handled yet
    #"pkg.tar.xz": {
    #    "devsuffix": "", "dash": "", "separator": "",
    #    "x86_64": "", "i586": ""
    #}
}

# TODO: automaticaly build the dictionnary from the active distros
# on OBS
Distribs = {
    "CentOS_5": ["x86_64", "i586"],
    "CentOS_6": ["x86_64", "i586"],
    "CentOS_7": ["x86_64"],
    "Debian_6.0": ["x86_64", "i586"],
    "Debian_7.0": ["x86_64", "i586"],
    "Debian_8.0": ["x86_64", "i586"],
    "Fedora_20": ["x86_64", "i586"],
    "Fedora_21": ["x86_64", "i586"],
    "Fedora_22": ["x86_64", "i586"],
    "Fedora_23": ["x86_64", "i586"],
    "Mageia_5_standard": ["x86_64", "i586"],
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
    "openSUSE_Leap_42.1": ["x86_64"],
    "openSUSE_Tumbleweed": ["x86_64", "i586"],
    "xUbuntu_12.04": ["x86_64", "i586"],
    "xUbuntu_14.04": ["x86_64", "i586"],
    "xUbuntu_14.10": ["x86_64", "i586"],
    "xUbuntu_15.04": ["x86_64", "i586"],
    "xUbuntu_15.10": ["x86_64", "i586"],
}
    #"openSUSE_Factory": ["x86_64", "i586"],
    #"openSUSE_Factory_ARM": ["aarch64", "armv7l", "armv6l"],
    #"Arch_Core": ["x86_64", "i586"],
    #"Arch_Extra": ["x86_64", "i586"],

#
# Handle the directories
#

if not os.path.exists(destination):
    os.makedirs(destination)
if binname == "mediaconch":
    if not os.path.exists(destination_server):
        os.makedirs(destination_server)
if prjkind == "gui":
    if not os.path.exists(destination_gui):
        os.makedirs(destination_gui)

# Once the initialisation of this script is done, the first thing
# to do is wait until everything is build on OBS.
waiting_loop()

# At this point, each enabled distros will be either in succeeded
# or failed state. We can update the DB.
update_DB()

# Then, fetch the packages.
get_packages_on_OBS()

# Send a confirmation mail if everything is ok, or else notify when
# a build has failed or a succeeded package has not been downloaded
verify_states_and_files()

# If we run for MC or MI, and this is a release
#if (prjkind == "gui") and (len(dlpages_table) > 1):
#    execfile( os.path.join( script_emplacement, "Generate_dl_pages.py" ))
