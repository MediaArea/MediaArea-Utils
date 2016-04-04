#!/usr/bin/env python
# -*- coding: utf-8 -*-

import MySQLdb
import time
import sys
import fnmatch
import os
import subprocess

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
                    host=Config["MySQL_host"],
                    user=Config["MySQL_user"],
                    passwd=Config["MySQL_passwd"],
                    db=Config["MySQL_db"])
        except MySQLdb.Error, e:
            self.running = True
            print "*** MySQL Error %d: %s ***" % (e.args[0], e.args[1])
            print "*** FATAL: quitting ***"
            sys.exit(1)

    def close(self):
        if self.open:
            self.sql.commit()
            return self.cursor.close()
        else:
            print "*** close: No DB cursor is open! ***"
            return 0

    def execute(self, query):
        print "---------------- SQL QUERY ----------------"
        print query
        print "-------------------------------------------"
        self.cursor = self.sql.cursor()
        self.cursor.execute(query)
        self.sql.commit()
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

##################################################################
def Initialize_DB():

    # If the tables doesn’t exist, create it
    Cursor.execute("SELECT * FROM information_schema.tables WHERE table_schema = '" + Config["MySQL_db"] + "' AND table_name = '" + Table + "';")
    Result = 0
    Result = Cursor.rowcount()
    if Result == 0:
        Cursor.execute("CREATE TABLE IF NOT EXISTS " + Table
                        + """
                            (
                                distrib varchar(50),
                                arch varchar(10),
                                state tinyint(4)
                            )
                            DEFAULT CHARACTER SET utf8
                            DEFAULT COLLATE utf8_general_ci;
                        """)

    if Release == True:
        Cursor.execute("SELECT * FROM information_schema.tables WHERE table_schema = '" + Config["MySQL_db"] + "' AND table_name = '" + DL_pages_table + "';")
        Result = 0
        Result = Cursor.rowcount()
        if Result == 0:
            Cursor.execute("CREATE TABLE IF NOT EXISTS " + DL_pages_table
                            + "("
                            + DB_structure
                            + ") DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;")

    # Ensure that all the distribs in the dictionary are presents
    # in the DB

    for Distrib_name in Distribs.keys():

        for Arch in Distribs[Distrib_name]:

            Cursor.execute("SELECT * FROM `" + Table + "` WHERE distrib = '" + Distrib_name + "' AND arch = '" + Arch + "';")
            Result = 0
            Result = Cursor.rowcount()
            # If the couple (Distrib_name, Arch) isn't already
            # in the table, we insert it
            if Result == 0:
                Cursor.execute("INSERT INTO `" + Table + "` (distrib, arch) VALUES ('" + Distrib_name + "', '" + Arch + "');")

    # Ensure that the DB doesn’t keep distribs the distros which
    # are no longer in the dictionary. The DL_pages_table is not
    # affected since a distrib can be removed from builds but still
    # wanted in the download tables.

    Cursor.execute("SELECT * FROM `" + Table + "`")
    DB_distribs = Cursor.fetchall()

    for DB_dist in DB_distribs:
        DB_distrib_name = DB_dist[0]
        DB_arch = DB_dist[1]
        if Distribs.has_key(DB_distrib_name):
            # If the distrib is present, but this arch has been
            # removed
            if Distribs[DB_distrib_name].count(DB_arch) == 0:
                Cursor.execute("DELETE FROM `" + Table + "` WHERE distrib = '" + DB_distrib_name + "' AND arch = '" + DB_arch + "';")
        else:
            Cursor.execute("DELETE FROM `" + Table + "` WHERE distrib = '" + DB_distrib_name + "' AND arch = '" + DB_arch + "';")

##################################################################
def Waiting_loop():

    Count = 0

    # We wait for max 9h (600*20)+(1200*17)
    while Count < 38:

        Count = Count + 1

        # At first, check every 10mn during 3h20
        if Count < 20:
            if Count == 1:
                print "Wait 10mn..."
            else:
                print "All builds aren’t finished yet, wait another 10mn..."
            time.sleep(600)

        # Past 3h30, trigger rebuilds
        else:
            print "All builds aren’t finished yet, trigger rebuild(s) if there are still distribs in scheduled state, and wait 20mn..."
            for Distrib_name in Distribs.keys():
                for Arch in Distribs[Distrib_name]:
                    Params = "osc results " + MA_project \
                           + " |grep " + Distrib_name \
                           + " |grep " + Arch \
                           + " |awk '{print $3}' |sed 's/*//'"
                    Result = subprocess.check_output(Params, shell=True).strip()
                    if Result == "scheduled":
                        print "Trigger rebuild for " + Distrib_name + " (" + Arch + ")"
                        subprocess.call(["osc", "rebuild", MA_project, Distrib_name, Arch])
                        
            time.sleep(1200)

        # Check if the builds are done on OBS
        Params = "osc results " + MA_project \
               + " |awk '{print $3}' |sed 's/*//' |grep -v 'excluded\|disabled\|broken\|unresolvable\|failed\|succeeded' |wc -l"
        Result = subprocess.check_output(Params, shell=True).strip()
        # When all the distros are build, Result will equal 0
        if Result == "0":
            break

        # If Result ≠ 0 and Count = 37, then we have wait for 9h
        # and all the distros aren’t build. This while loop will
        # exit at the next iteration, and in the error mail we’ll
        # specify that the timeout was reached.
        Timeout = False
        if Count == 37:
            Timeout = True

##################################################################
def Update_DB():

    # We update the table with the results of the build
    for Distrib_name in Distribs.keys():
        for Arch in Distribs[Distrib_name]:
            # We take "grep 'Distrib_name '" instead of "grep Distrib_name"
            # because the name of a distrib can be included in the
            # names of another distribs (ie SLE_11 and SLE_11_SPx)
            Params = "osc results " + MA_project \
                   + " |grep '" + Distrib_name + " '"\
                   + " |grep " + Arch \
                   + " |awk '{print $3}' |sed 's/*//'"
            Result = subprocess.check_output(Params, shell=True).strip()
            # First case : if the state is disabled, excluded or
            # unknown
            State = "0"
            if Result == "succeeded":
                State = "1"
            if Result == "broken" or Result == "unresolvable" or Result == "failed" or Result == "blocked" or Result == "scheduled" or Result == "building" or Result == "finished":
                State = "2"
            Cursor.execute("UPDATE `" + Table + "` SET state= '" + State + "' WHERE distrib = '" + Distrib_name + "' AND arch = '" + Arch + "';")

##################################################################
def Get_packages_on_OBS():

    Cursor.execute("SELECT * FROM `" + Table + "`")
    DB_distribs = Cursor.fetchall()

    for DB_dist in DB_distribs:

        Distrib_name = DB_dist[0]
        Arch = DB_dist[1]
        State = DB_dist[2]

        # State == 1 if build succeeded
        if State == 1:

            print
            print "API commands for " + Distrib_name + " (" + Arch + ")"
            print

            # Initialization depending on the distrib’s family
            Revision = ""
            if fnmatch.fnmatch(Distrib_name, "Debian*") or \
                    fnmatch.fnmatch(Distrib_name, "xUbuntu*"):
                Package_type = "deb"
                Revision = "-1"
            if fnmatch.fnmatch(Distrib_name, "RHEL*") or \
                    fnmatch.fnmatch(Distrib_name, "CentOS*") or \
                    fnmatch.fnmatch(Distrib_name, "Fedora*"):
                Package_type = "rpm"
                Package_infos[Package_type]["i586"] = "i686"
            if fnmatch.fnmatch(Distrib_name, "SLE*") or \
                    fnmatch.fnmatch(Distrib_name, "openSUSE*"):
                Package_type = "rpm"
                Package_infos[Package_type]["i586"] = "i586"
            if fnmatch.fnmatch(Distrib_name, "Mageia*"):
                Package_type = "rpm"
                Package_infos[Package_type]["i586"] = "i586"
            #if fnmatch.fnmatch(Distrib_name, "Arch*"):
            #    Package_type = "pkg.tar.xz"

            ###############
            # Bin package #
            ###############

            # Bin = the library package in case of a library, or
            # the cli package otherwise

            # The wanted name for the package, under the form:
            # name[_|-]version[-1][_|.]Arch.[deb|rpm]
            Bin_name_wanted = Bin_name \
                    + Package_infos[Package_type]["dash"] + Version \
                    + Revision \
                    + Package_infos[Package_type]["separator"] + Package_infos[Package_type][Arch] \
                    + "." + Distrib_name \
                    + "." + Package_type
            Bin_name_final = os.path.join(Destination, Bin_name_wanted)

            Bin_name_obs_side = "0"
            # Fetch the name of the package on OBS
            # We take “ deb" ” to avoid the *.debian.txz files
            Params = "osc api /build/" + OBS_project \
                   + "/" + Distrib_name \
                   + "/" + Arch \
                   + "/" + OBS_package \
                   + " |grep 'rpm\"\|deb\"'" \
                   + " |grep " + Bin_name + Package_infos[Package_type]["dash"] + Version \
                   + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
            print "Name of the bin package on OBS:"
            print Params
            Bin_name_obs_side = subprocess.check_output(Params, shell=True).strip()

            # If the bin package is build
            if len(Bin_name_obs_side) > 1:
                Params_getpackage = \
                        "osc api /build/" + OBS_project \
                        + "/" + Distrib_name \
                        + "/" + Arch \
                        + "/" + OBS_package \
                        + "/" + Bin_name_obs_side \
                        + " > " + Bin_name_final
                print "Command to fetch the bin package:"
                print Params_getpackage
                print
                subprocess.call(Params_getpackage, shell=True)

                # This is potentially a spam tank, but I leave the
                # mails here because:
                # 1. it allows to have the command that have
                # failed = more convenient to understand the issue
                # 2. because of the multiple runs for the
                # multiple OBS repos (Project_debX), the final test
                # can miss some download errors.

                # If the bin package is build, but hasn’t been
                # downloaded for some raison.
                if not os.path.isfile(Bin_name_final):
                    Params = \
                           "echo '" + Distrib_name + " (" + Arch + "): the bin package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                           + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                           + " " + Config["Email_to"]
                    subprocess.call(Params, shell=True)
            else:
                print "ERROR: fail to get the name of the bin package on OBS."
                print

            #################
            # Debug package #
            #################

            # name-[dbg|debuginfo][_|-]version[-1][_|.]Arch.[deb|rpm]
            Debug_name_wanted = Debug_name \
                    + Package_infos[Package_type]["debugsuffix"] \
                    + Package_infos[Package_type]["dash"] + Version \
                    + Revision \
                    + Package_infos[Package_type]["separator"] + Package_infos[Package_type][Arch] \
                    + "." + Distrib_name \
                    + "." + Package_type
            Debug_name_final = os.path.join(Destination, Debug_name_wanted)

            Debug_name_obs_side = "0"
            # Fetch the name of the package on OBS
            Params = "osc api /build/" + OBS_project \
                   + "/" + Distrib_name \
                   + "/" + Arch \
                   + "/" + OBS_package \
                   + " |grep 'rpm\"\|deb\"'" \
                   + " |grep " + Debug_name + Package_infos[Package_type]["debugsuffix"] + Package_infos[Package_type]["dash"] + Version \
                   + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
            print "Name of the debug package on OBS:"
            print Params
            Debug_name_obs_side = subprocess.check_output(Params, shell=True).strip()

            # If the debug package is build
            if len(Debug_name_obs_side) > 1:
                Params_getpackage = \
                        "osc api /build/" + OBS_project \
                        + "/" + Distrib_name \
                        + "/" + Arch \
                        + "/" + OBS_package \
                        + "/" + Debug_name_obs_side \
                        + " > " + Debug_name_final
                print "Command to fetch the debug package:"
                print Params_getpackage
                print
                subprocess.call(Params_getpackage, shell=True)

                # If the debug package is build, but hasn’t been
                # downloaded for some raison.
                if not os.path.isfile(Debug_name_final):
                    Params = \
                           "echo '" + Distrib_name + " (" + Arch + "): the debug package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                           + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                           + " " + Config["Email_to"]
                    subprocess.call(Params, shell=True)
            else:
                # Debug packages aren’t perfectly handled on OBS
                #print "ERROR: fail to get the name of the debug package on OBS."
                print

            ###############
            # Dev package #
            ###############

            if Project_kind == "lib":

                # name-dev[el][_|-]version[-1][_|.]Arch.[deb|rpm]
                Dev_name_wanted = Debug_name \
                        + Package_infos[Package_type]["devsuffix"] \
                        + Package_infos[Package_type]["dash"] + Version \
                        + Revision \
                        + Package_infos[Package_type]["separator"] \
                        + Package_infos[Package_type][Arch] \
                        + "." + Distrib_name \
                        + "." + Package_type
                Dev_name_final = os.path.join(Destination, Dev_name_wanted)

                Dev_name_obs_side = "0"
                # Fetch the name of the package on OBS
                Params = "osc api /build/" + OBS_project \
                       + "/" + Distrib_name \
                       + "/" + Arch \
                       + "/" + OBS_package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + Debug_name + Package_infos[Package_type]["devsuffix"] + Package_infos[Package_type]["dash"] + Version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the dev package on OBS:"
                print Params
                Dev_name_obs_side = subprocess.check_output(Params, shell=True).strip()

                # If the dev package is build
                if len(Dev_name_obs_side) > 1:
                    Params_getpackage = \
                            "osc api /build/" + OBS_project \
                            + "/" + Distrib_name \
                            + "/" + Arch \
                            + "/" + OBS_package \
                            + "/" + Dev_name_obs_side \
                            + " > " + Dev_name_final
                    print "Command to fetch the dev package:"
                    print Params_getpackage
                    print
                    subprocess.call(Params_getpackage, shell=True)

                    # If the dev package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(Dev_name_final):
                        Params = \
                               "echo '" + Distrib_name + " (" + Arch + "): the dev package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                               + " " + Config["Email_to"]
                        subprocess.call(Params, shell=True)
                else:
                    print "ERROR: fail to get the name of the dev package on OBS."
                    print

            ###############
            # Doc package #
            ###############

                # name-doc[_|-]version[-1][_|.]Arch.[deb|rpm]
                Doc_name_wanted = Debug_name + "-doc" \
                        + Package_infos[Package_type]["dash"] + Version \
                        + Revision \
                        + Package_infos[Package_type]["separator"] + Package_infos[Package_type][Arch] \
                        + "." + Distrib_name \
                        + "." + Package_type
                Doc_name_final = os.path.join(Destination, Doc_name_wanted)
    
                Doc_name_obs_side = "0"
                # Fetch the name of the package on OBS
                Params = "osc api /build/" + OBS_project \
                       + "/" + Distrib_name \
                       + "/" + Arch \
                       + "/" + OBS_package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep doc |grep -v src |awk -F '\"' '{print $2}'"
                print "Name of the doc package on OBS:"
                print Params
                Doc_name_obs_side = subprocess.check_output(Params, shell=True).strip()
    
                # If the doc package is build
                if len(Doc_name_obs_side) > 1:
                    Params_getpackage = \
                            "osc api /build/" + OBS_project \
                            + "/" + Distrib_name \
                            + "/" + Arch \
                            + "/" + OBS_package \
                            + "/" + Doc_name_obs_side \
                            + " > " + Doc_name_final
                    print "Command to fetch the doc package:"
                    print Params_getpackage
                    print
                    subprocess.call(Params_getpackage, shell=True)
    
                    # If the doc package is build, but hasn’t been
                    # downloaded for some raison.
                    if not os.path.isfile(Doc_name_final):
                        Params = \
                               "echo '" + Distrib_name + " (" + Arch + "): the doc package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                               + " " + Config["Email_to"]
                        subprocess.call(Params, shell=True)
                else:
                    print "ERROR: fail to get the name of the doc package on OBS."
                    print

            ###############
            # GUI package #
            ###############

            if Project_kind == "gui":

                # name-gui[_|-]version[-1][_|.]Arch.[deb|rpm]
                Gui_name_wanted = Bin_name + "-gui" \
                        + Package_infos[Package_type]["dash"] + Version \
                        + Revision \
                        + Package_infos[Package_type]["separator"] + Package_infos[Package_type][Arch] \
                        + "." + Distrib_name \
                        + "." + Package_type
                Gui_name_final = os.path.join(Destination_gui, Gui_name_wanted)

                Gui_name_obs_side = "0"
                # Fetch the name of the package on OBS
                Params = "osc api /build/" + OBS_project \
                       + "/" + Distrib_name \
                       + "/" + Arch \
                       + "/" + OBS_package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + Bin_name + "-gui" + Package_infos[Package_type]["dash"] + Version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the gui package on OBS:"
                print Params
                Gui_name_obs_side = subprocess.check_output(Params, shell=True).strip()

                # If the gui package is build
                if len(Gui_name_obs_side) > 1:
                    Params_getpackage = \
                            "osc api /build/" + OBS_project \
                            + "/" + Distrib_name \
                            + "/" + Arch \
                            + "/" + OBS_package \
                            + "/" + Gui_name_obs_side \
                            + " > " + Gui_name_final
                    print "Command to fetch the gui package:"
                    print Params_getpackage
                    print
                    subprocess.call(Params_getpackage, shell=True)

                    # If the gui package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(Gui_name_final):
                        Params = \
                               "echo '" + Distrib_name + " (" + Arch + "): the gui package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                               + " " + Config["Email_to"]
                        subprocess.call(Params, shell=True)
                else:
                    print "ERROR: fail to get the name of the gui package on OBS."
                    print

            ##################
            # Server package #
            ##################

            if Bin_name == "mediaconch":

                # name-server[_|-]version[-1][_|.]Arch.[deb|rpm]
                Server_name_wanted = Bin_name + "-server" \
                        + Package_infos[Package_type]["dash"] + Version \
                        + Revision \
                        + Package_infos[Package_type]["separator"] + Package_infos[Package_type][Arch] \
                        + "." + Distrib_name \
                        + "." + Package_type
                Server_name_final = os.path.join(Destination_server, Server_name_wanted)

                Server_name_obs_side = "0"
                # Fetch the name of the package on OBS
                Params = "osc api /build/" + OBS_project \
                       + "/" + Distrib_name \
                       + "/" + Arch \
                       + "/" + OBS_package \
                       + " |grep 'rpm\"\|deb\"'" \
                       + " |grep " + Bin_name + "-server" + Package_infos[Package_type]["dash"] + Version \
                       + " |grep -v src |grep -v doc |awk -F '\"' '{print $2}'"
                print "Name of the server package on OBS:"
                print Params
                Server_name_obs_side = subprocess.check_output(Params, shell=True).strip()

                # If the server package is build
                if len(Server_name_obs_side) > 1:
                    Params_getpackage = \
                            "osc api /build/" + OBS_project \
                            + "/" + Distrib_name \
                            + "/" + Arch \
                            + "/" + OBS_package \
                            + "/" + Server_name_obs_side \
                            + " > " + Server_name_final
                    print "Command to fetch the server package:"
                    print Params_getpackage
                    print
                    subprocess.call(Params_getpackage, shell=True)

                    # If the server package is build, but hasn’t
                    # been downloaded for some raison.
                    if not os.path.isfile(Server_name_final):
                        Params = \
                               "echo '" + Distrib_name + " (" + Arch + "): the server package is build, but hasn’t been downloaded.\n\nThe command line was:\n" + Params_getpackage + "'" \
                               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                               + " " + Config["Email_to"]
                        subprocess.call(Params, shell=True)
                else:
                    print "ERROR: fail to get the name of the server package on OBS."
                    print

            ###########################
            # Put the filenames in DB #
            ###########################

            # If we run for a release
            if Release == True:

                # First, ensure that all the succeeded distribs are
                # presents in the DB
                Cursor.execute("SELECT * FROM `" + DL_pages_table + "` WHERE platform = '" + Distrib_name + "' AND arch = '" + Arch + "';")
                Result = 0
                Result = Cursor.rowcount()
                if Result == 0:
                    Cursor.execute("INSERT INTO `" + DL_pages_table + "` (platform, arch) VALUES ('" + Distrib_name + "', '" + Arch + "');")

                # For the libs
                if Project_kind == "lib":
                    Cursor.execute("UPDATE `" + DL_pages_table + "` SET"\
                            + " version = '" + Version + "'," \
                            + " libname = '" + Bin_name_wanted + "'," \
                            + " libnamedbg = '" + Debug_name_wanted + "'," \
                            + " libnamedev = '" + Dev_name_wanted + "'" \
                            + " WHERE platform = '" + Distrib_name + "'" \
                            + " AND arch = '" + Arch + "';")

                # For MC
                if Bin_name == "mediaconch":
                    Cursor.execute("UPDATE `" + DL_pages_table + "` SET"\
                            + " version = '" + Version + "'," \
                            + " cliname = '" + Bin_name_wanted + "'," \
                            + " clinamedbg = '" + Debug_name_wanted + "'," \
                            + " servername = '" + Server_name_wanted + "'," \
                            + " guiname = '" + Gui_name_wanted + "'" \
                            + " WHERE platform = '" + Distrib_name + "'" \
                            + " AND arch = '" + Arch + "';")

                # For MI
                if Bin_name == "mediainfo":
                    Cursor.execute("UPDATE `" + DL_pages_table + "` SET"\
                            + " version = '" + Version + "'," \
                            + " cliname = '" + Bin_name_wanted + "'," \
                            + " clinamedbg = '" + Debug_name_wanted + "'," \
                            + " guiname = '" + Gui_name_wanted + "'" \
                            + " WHERE platform = '" + Distrib_name + "'" \
                            + " AND arch = '" + Arch + "';")


            print "-----------------------"

##################################################################
def Verify_states_and_files():

    Cursor.execute("SELECT * FROM `" + Table + "`")
    DB_distribs = Cursor.fetchall()

    Number_succeeded = 0
    Dists_failed = []

    for DB_dist in DB_distribs:

        Distrib_name = DB_dist[0]
        Arch = DB_dist[1]
        State = DB_dist[2]

        # State == 1 if build succeeded
        if State == 1:
            Number_succeeded = Number_succeeded + 1

        # State == 2 if build failed
        if State == 2:
            Dists_failed.append(DB_dist)

    print "(In case the mails can’t be send:)"
    print "succeeded: " + str(Number_succeeded)

    ################
    # Bin packages #
    ################

    # Careful: if multiple instances run at the same time (debX)
    # and one of them doesn’t download its packages, the problem
    # may not be detected. Because the packages downloaded by other
    # instances will be counted in Number_bin.

    Number_bin = 0
    Params = "ls " + Destination + "/" + Bin_name + "*" + Version + "*" \
           + " |grep 'rpm\|deb'" \
           + " |grep -v 'dbg\|debug'" \
           + " |wc -l"
    Result = subprocess.check_output(Params, shell=True).strip()
    Number_bin = int(Result)

    # It’s not a good idea to put it before the previous line, as
    # in some case Result is an int, and other time it’s a str…
    print "bin: " + str(Number_bin)

    if Number_bin < Number_succeeded:
        Params = \
               "echo 'OBS project: " + OBS_project + "\n" \
               + "OBS package: " + OBS_package + "\n" \
               + "Version: " + Version + "\n\n" \
               + "The number of downloaded bin packages is lower than the number of succeeded bin packages on OBS:\n" \
               + str(Number_succeeded) + " succeeded and " + str(Number_bin) + " downloaded.'" \
               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
               + " " + Config["Email_to"]
        subprocess.call(Params, shell=True)

    ##################
    # Debug packages #
    ##################

    Number_debug = 0
    Params = "ls " + Destination + "/" + Debug_name + "*" \
           + " |grep 'rpm\|deb'" \
           + " |grep 'dbg\|debug'" \
           + " |wc -l"
    Result = subprocess.check_output(Params, shell=True).strip()
    Number_debug = int(Result)

    print "dbg: " + str(Number_debug)

    # Debug packages aren’t perfectly handled on OBS
    #if Number_debug < Number_succeeded:
    #    Params = \
    #           "echo 'OBS project: " + OBS_project + "\n" \
    #           + "OBS package: " + OBS_package + "\n" \
    #           + "Version: " + Version + "\n\n" \
    #           "The number of downloaded debug packages is lower than the number of succeeded debug packages on OBS:\n" \
    #           + str(Number_succeeded) + " succeeded and " + str(Number_debug) + " downloaded.'" \
    #           + " |mailx -s '[BR lin] Problem with " + OBS_package + "'"
    #           + " " + Config["Email_to"]
    #    subprocess.call(Params, shell=True)

    ################
    # Dev packages #
    ################

    if Project_kind == "lib":
        Number_dev = 0
        Params = "ls " + Destination + "/" + Debug_name + "*" \
               + " |grep 'rpm\|deb'" \
               + " |grep 'dev\|devel'" \
               + " |wc -l"
        Result = subprocess.check_output(Params, shell=True).strip()
        Number_dev = int(Result)
        
        print "dev: " + str(Number_dev)

        if Number_dev < Number_succeeded:
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   "The number of downloaded dev packages is lower than the number of succeeded dev packages on OBS:\n" \
                   + str(Number_succeeded) + " succeeded and " + str(Number_dev) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)

        ################
        # Doc packages #
        ################
    
        Number_doc = 0
        Params = "ls " + Destination + "/" + Debug_name + "-doc*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        Result = subprocess.check_output(Params, shell=True).strip()
        Number_doc = int(Result)

        print "doc: " + str(Number_doc)

        # Doc packages aren’t generated on debX and mgaX repos
        if Number_doc < Number_succeeded and not fnmatch.fnmatch(OBS_package, "*_deb?") and not fnmatch.fnmatch(OBS_package, "*_mga?"):
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   "The number of downloaded doc packages is lower than the number of succeeded doc packages on OBS:\n" \
                   + str(Number_succeeded) + " succeeded and " + str(Number_doc) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)

    ###################
    # Server packages #
    ###################

    if Bin_name == "mediaconch":
        Number_server = 0
        Params = "ls " + Destination_server + "/" + Bin_name + "-server" + "?" + Version + "*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        Result = subprocess.check_output(Params, shell=True).strip()
        Number_server = int(Result)
        
        print "server: " + str(Number_server)

        if Number_server < Number_succeeded:
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   "The number of downloaded server packages is lower than the number of succeeded server packages on OBS:\n" \
                   + str(Number_succeeded) + " succeeded and " + str(Number_server) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)

    ################
    # GUI packages #
    ################

    if Project_kind == "gui":
        Number_gui = 0
        Params = "ls " + Destination_gui + "/" + Bin_name + "-gui" + "?" + Version + "*" \
               + " |grep 'rpm\|deb'" \
               + " |wc -l"
        Result = subprocess.check_output(Params, shell=True).strip()
        Number_gui = int(Result)
        
        print "gui: " + str(Number_gui)

        if Number_gui < Number_succeeded:
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   "The number of downloaded gui packages is lower than the number of succeeded gui packages on OBS:\n" \
                   + str(Number_succeeded) + " succeeded and " + str(Number_gui) + " downloaded.'" \
                   + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)

    ###################
    # Failed packages #
    ###################

    if len(Dists_failed) > 0:

        Failed_list = ""
        for Dist in Dists_failed:
            Distrib_name = Dist[0]
            Arch = Dist[1]
            Failed_list = Failed_list + "* " + str(Distrib_name) + " (" + str(Arch) + ")\n"

        print "\nFailed:\n" + Failed_list

        Timeout_message = ""
        if Timeout:
            Timeout_message = "After more than 9 hours, the builds weren’t over. The script will download whatever is available.\n\n"

        Params = \
               "echo 'OBS project: " + OBS_project + "\n" \
               + "OBS package: " + OBS_package + "\n" \
               + "Version: " + Version + "\n\n" \
               + Timeout_message \
               + "The build have fail on OBS for:\n" + Failed_list + "'" \
               + " |mailx -s '[BR lin] Problem with " + OBS_package + "'" \
               + " " + Config["Email_to"]
        subprocess.call(Params, shell=True)

    # Confirmation mails

    Quotient, Seconds = divmod(time.time()-Time_start, 60)
    Hours, Minutes = divmod(Quotient, 60)
    if Hours < 10:
        Total_time = "0" + str("%d" % Hours)
    else:
        Total_time = str("%d" % Hours)
    Total_time = Total_time + ":"
    if Minutes < 10:
        Total_time = Total_time + "0" + str("%d" % Minutes)
    else:
        Total_time = Total_time + str("%d" % Minutes)
    Total_time = Total_time + ":"
    if Seconds < 10:
        Total_time = Total_time + "0" + str("%d" % Seconds)
    else:
        Total_time = Total_time + str("%d" % Seconds)

    print "\nHandle_OBS_results.py has run during: " + Total_time

    # Don’t send a confirmation mail for the debX and mgaX repos
    if Project_kind == "lib" and not fnmatch.fnmatch(OBS_package, "*_deb?") and not fnmatch.fnmatch(OBS_package, "*_mga?"):
        # We use >= and not ==, because there may be other repos
        # which have ran into the same directory (Project_debX).
        if len(Dists_failed) == 0 and Number_bin >= Number_succeeded and Number_dev >= Number_succeeded and Number_doc >= Number_succeeded:
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   + "SUCCESS\n\n" \
                   + "* " + str(Number_succeeded) + " builds succeeded;\n" \
                   + "* " + str(Number_bin) + " bin (" + Bin_name + ") packages downloaded;\n" \
                   + "* " + str(Number_dev) + " dev packages downloaded;\n" \
                   + "* " + str(Number_debug) + " debug packages downloaded (debug packages aren’t perfectly handled on OBS);\n" \
                   + "* " + str(Number_doc) + " doc packages downloaded.\n\n" \
                   + "Handle_OBS_results.py has run during: " + Total_time + "'" \
                   + " |mailx -s '[BR lin] OK for " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)
    
    if Project_kind == "gui" and not fnmatch.fnmatch(OBS_package, "*_deb?") and not fnmatch.fnmatch(OBS_package, "*_mga?"):
        if len(Dists_failed) == 0 and Number_bin >= Number_succeeded and Number_gui >= Number_succeeded:
            Params = \
                   "echo 'OBS project: " + OBS_project + "\n" \
                   + "OBS package: " + OBS_package + "\n" \
                   + "Version: " + Version + "\n\n" \
                   + "SUCCESS\n\n" \
                   + "* " + str(Number_succeeded) + " builds succeeded;\n" \
                   + "* " + str(Number_bin) + " bin (CLI) packages downloaded;\n" \
                   + "* " + str(Number_debug) + " debug packages downloaded (debug packages aren’t perfectly handled on OBS);\n" \
                   + "* " + str(Number_gui) + " gui packages downloaded.\n\n" \
                   + "Handle_OBS_results.py has run during: " + Total_time + "'" \
                   + " |mailx -s '[BR lin] OK for " + OBS_package + "'" \
                   + " " + Config["Email_to"]
            subprocess.call(Params, shell=True)

##################################################################
# Main

Time_start = time.time()

#
# Arguments
#
# 1 $OBS_project (home:MediaArea_net[:snapshots])
# 2 $OBS_package (ZenLib, MediaInfoLib, …)
# 3 Version
# 4 Destination for the packages
# For MC: 5 Destination for the server packages and 6 for the GUI
# For MI: 5 Destination for the GUI packages

#
# Handle the variables
#

OBS_project = sys.argv[1]
OBS_package = sys.argv[2]
Version = sys.argv[3]
Destination = sys.argv[4]
# The directory from where the python script is executed
Script_emplacement = os.path.dirname(os.path.realpath(__file__))

Config = {}
execfile( os.path.join( Script_emplacement, "Handle_OBS_results.conf"), Config)
 
MA_project = OBS_project + "/" + OBS_package

# Various initializations
DL_pages_table = "0"
DB_structure = ""
Release = False
Timeout = False
Count = 0
Result = 0

if fnmatch.fnmatch(OBS_package, "ZenLib*"):
    Project_kind = "lib"
    Bin_name = "libzen0"
    Debug_name = "libzen"
    if fnmatch.fnmatch(OBS_project, "*:snapshots"):
        if OBS_package == "ZenLib":
            Table = "snapshots_obs_zl"
        elif OBS_package == "ZenLib_deb6":
            Table = "snapshots_obs_zl_deb6"
        elif OBS_package == "ZenLib_deb9":
            Table = "snapshots_obs_zl_deb9"
            Bin_name = "libzen0v5"
    else:
        DL_pages_table = "releases_dlpages_zl"
        DB_structure = """ 
            platform varchar(50),
            arch varchar(10),
            version varchar(18),
            libname varchar(120),
            libnamedbg varchar(120),
            libnamedev varchar(120)"""
        if OBS_package == "ZenLib":
            Table = "releases_obs_zl"
        elif OBS_package == "ZenLib_deb6":
            Table = "releases_obs_zl_deb6"
        elif OBS_package == "ZenLib_deb9":
            Table = "releases_obs_zl_deb9"
            Bin_name = "libzen0v5"

if OBS_package == "MediaInfoLib" or fnmatch.fnmatch(OBS_package, "MediaInfoLib_*"):
    Project_kind = "lib"
    Bin_name = "libmediainfo0"
    Debug_name = "libmediainfo"
    if fnmatch.fnmatch(OBS_project, "*:snapshots"):
        if OBS_package == "MediaInfoLib":
            Table = "snapshots_obs_mil"
        elif OBS_package == "MediaInfoLib_deb6":
            Table = "snapshots_obs_mil_deb6"
        elif OBS_package == "MediaInfoLib_deb9":
            Table = "snapshots_obs_mil_deb9"
            Bin_name = "libmediainfo0v5"
        # Since TinyXML2 is back as buildin for deb distribs
        #elif OBS_package == "MediaInfoLib_u12.04":
        #    Table = "snapshots_obs_mil_u12.04"
    else:
        DL_pages_table = "releases_dlpages_mil"
        DB_structure = """ 
            platform varchar(50),
            arch varchar(10),
            version varchar(18),
            libname varchar(120),
            libnamedbg varchar(120),
            libnamedev varchar(120)"""
        if OBS_package == "MediaInfoLib":
            Table = "releases_obs_mil"
        elif OBS_package == "MediaInfoLib_deb6":
            Table = "releases_obs_mil_deb6"
        elif OBS_package == "MediaInfoLib_deb9":
            Table = "releases_obs_mil_deb9"
            Bin_name = "libmediainfo0v5"
        # Since TinyXML2 is back as buildin for deb distribs
        #elif OBS_package == "MediaInfoLib_u12.04":
        #    Table = "releases_obs_mil_u12.04"

if fnmatch.fnmatch(OBS_package, "MediaConch*"):
    Project_kind = "gui"
    Bin_name = "mediaconch"
    Debug_name = "mediaconch"
    Destination_server = sys.argv[5]
    Destination_gui = sys.argv[6]
    if fnmatch.fnmatch(OBS_project, "*:snapshots"):
        if OBS_package == "MediaConch":
            Table = "snapshots_obs_mc"
        if OBS_package == "MediaConch_deb9":
            Table = "snapshots_obs_mc_deb9"
    else:
        DL_pages_table = "releases_dlpages_mc"
        DB_structure = """ 
            platform varchar(50),
            arch varchar(10),
            version varchar(18),
            cliname varchar(120),
            clinamedbg varchar(120),
            servername varchar(120),
            servernamedbg varchar(120),
            guiname varchar(120),
            guinamedbg varchar(120)"""
        if OBS_package == "MediaConch":
            Table = "releases_obs_mc"
        if OBS_package == "MediaConch_deb9":
            Table = "releases_obs_mc_deb9"

# Careful to not catch MediaInfoLib
if OBS_package == "MediaInfo" or fnmatch.fnmatch(OBS_package, "MediaInfo_*"):
    Project_kind = "gui"
    Bin_name = "mediainfo"
    Debug_name = "mediainfo"
    Destination_gui = sys.argv[5]
    if fnmatch.fnmatch(OBS_project, "*:snapshots"):
        if OBS_package == "MediaInfo":
            Table = "snapshots_obs_mi"
        elif OBS_package == "MediaInfo_deb6":
            Table = "snapshots_obs_mi_deb6"
        elif OBS_package == "MediaInfo_deb7":
            Table = "snapshots_obs_mi_deb7"
        elif OBS_package == "MediaInfo_deb9":
            Table = "snapshots_obs_mi_deb9"
        elif OBS_package == "MediaInfo_mga5":
            Table = "snapshots_obs_mi_mga5"
    else:
        DL_pages_table = "releases_dlpages_mi"
        DB_structure = """ 
            platform varchar(50),
            arch varchar(10),
            version varchar(18),
            cliname varchar(120),
            clinamedbg varchar(120),
            guiname varchar(120),
            guinamedbg varchar(120)"""
        if OBS_package == "MediaInfo":
            Table = "releases_obs_mi"
        elif OBS_package == "MediaInfo_deb6":
            Table = "releases_obs_mi_deb6"
        elif OBS_package == "MediaInfo_deb7":
            Table = "releases_obs_mi_deb7"
        elif OBS_package == "MediaInfo_deb9":
            Table = "releases_obs_mi_deb9"
        elif OBS_package == "MediaInfo_mga5":
            Table = "releases_obs_mi_mga5"

if len(DL_pages_table) > 1:
    Release = True

# The architecture names (x86_64, i586, …) are imposed by OBS.
#
# If an architecture is actived on OBS, but not listed here, 
# Package_infos[Package_type][Arch] will raise a KeyError.
#
# In the declaration of a dictionary, you MUST put spaces after the
# commas, if not python can behave strangely.
#
Package_infos = {
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
    #"Arch_Core": ["x86_64", "i586"],
    #"Arch_Extra": ["x86_64", "i586"],
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
    "SLE_12_SP1": ["x86_64"],
    "openSUSE_11.4": ["x86_64", "i586"],
    "openSUSE_13.1": ["x86_64", "i586"],
    "openSUSE_13.2": ["x86_64", "i586"],
    "openSUSE_Leap_42.1": ["x86_64"],
    "openSUSE_Tumbleweed": ["x86_64", "i586"],
    #"openSUSE_Factory": ["x86_64", "i586"],
    #"openSUSE_Factory_ARM": ["aarch64", "armv7l", "armv6l"],
    "xUbuntu_12.04": ["x86_64", "i586"],
    "xUbuntu_14.04": ["x86_64", "i586"],
    "xUbuntu_14.10": ["x86_64", "i586"],
    "xUbuntu_15.04": ["x86_64", "i586"],
    "xUbuntu_15.10": ["x86_64", "i586"],
}

#
# Handle the directories
#

if not os.path.exists(Destination):
    os.makedirs(Destination)
if Bin_name == "mediaconch":
    if not os.path.exists(Destination_server):
        os.makedirs(Destination_server)
if Project_kind == "gui":
    if not os.path.exists(Destination_gui):
        os.makedirs(Destination_gui)

# Open the access to the DB
Cursor = mysql()

# Ensure that the DB is synchronous with OBS.
Initialize_DB()

# Once the initialisation of this script is done, the first thing
# to do is wait until everything is build on OBS.
Waiting_loop()

# At this point, each enabled distros will be either in succeeded
# or failed state. We can update the DB.
Update_DB()

# Then, fetch the packages.
Get_packages_on_OBS()

# Send a confirmation mail if everything is ok, or else notify when
# a build has failed or a succeeded package has not been downloaded
Verify_states_and_files()

# Close the access to the DB
Cursor.close()

# If we run for MC or MI (no DL pages for ZL and MIL, so we test
# Project_kind), and this is a release
#if Bin_name == "mediaconch" and Release == True:
#    execfile( os.path.join( Script_emplacement, "Generate_DL_pages.py mc linux" ))
#if Bin_name == "mediainfo" and Release == True:
#    execfile( os.path.join( Script_emplacement, "Generate_DL_pages.py mi linux" ))
