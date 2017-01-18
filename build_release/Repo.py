from glob import glob

import subprocess
import datetime
import os.path
import fnmatch
import pexpect
import shutil
import os
import re

#
# Sign_rpm_package - sign the given rpm with the configured key
#
def Sign_rpm_package(Package):
    Command = "rpm --resign --define '_gpg_name %s' %s" % (Configuration["Repo_key"]["key"], Package)

    Proc = pexpect.spawn(Command, env={"LC_ALL": "C"})
    Proc.expect("Enter pass phrase: ")
    Proc.sendline(open(Configuration["Repo_key"]["passfile"], "r").read())
    Proc.expect(pexpect.EOF)

    # Verify signature
    Command = ["rpm", "-K", Package]
    if subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT) != 0:
        print("ERROR: unable to sign rpm package %s" % Package)

#
# Create_repo_rpm - create repo activation package
#
def Create_repo_rpm(Path, Repo, Distribution, Release = False):
    Repo_directory = os.path.relpath(Path, Configuration["Repo_path"])

    Repo_file = Configuration["Repo_file_template"].replace("REPO_NAME", Repo)
    Repo_file = Repo_file.replace("REPO_URL", Configuration["Repo_url"])
    Repo_file = Repo_file.replace("REPO_DIRECTORY", Repo_directory)
    Repo_file = Repo_file.replace("DISTRIBUTION", Distribution.replace("_", " "))

    Repo_spec = Configuration["Repo_spec_template"].replace("REPO_NAME", Repo)
    Repo_spec = Repo_spec.replace("REPO_URL", Configuration["Repo_url"])
    Repo_spec = Repo_spec.replace("REPO_DIRECTORY", Repo_directory)
    Repo_spec = Repo_spec.replace("DISTRIBUTION", Distribution.replace("_", " "))
    Repo_spec = Repo_spec.replace("DATE", datetime.date.today().strftime("%a %b %d %Y"))

    Build_root = os.path.join(os.getenv("HOME"), "rpmbuild")

    for Directory in ["BUILD", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
            if not os.path.exists(os.path.join(Build_root, Directory)):
                os.makedirs(os.path.join(Build_root, Directory))

    # Clean buildroot
    Package_filename = os.path.join(Build_root, "RPMS", "noarch", "repo-%s-1.0-1.noarch.rpm" % Repo)
    Repo_filename = os.path.join(Build_root, "SOURCES", "repo-%s.repo" % Repo)
    Spec_filename = os.path.join(Build_root, "SPECS", "repo-%s.spec" % Repo)
    Key_filename = os.path.join(Build_root, "SOURCES", "GPG-KEY-%s" % Repo)

    for File in [Package_filename, Repo_filename, Spec_filename, Key_filename]:
        if os.path.exists(File):
            os.remove(File)

    # Add repo file
    Destination = open(Repo_filename, "w")
    Destination.write(Repo_file)
    Destination.close()

    # Add spec file
    Destination = open(Spec_filename, "w")
    Destination.write(Repo_spec)
    Destination.close()

    # Add key
    Destination = open(Key_filename, "w")
    Command = ["gpg", "--export", "--armor", "-u", Configuration["Repo_key"]["key"]]
    subprocess.call(Command, stdout=Destination)
    Destination.close()

    # Make rpm package
    Command = ["rpmbuild", "-bb", Spec_filename]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    Package_destination = os.path.join(Path, "repo-%s-1.0-1.%s.noarch.rpm" % (Repo, Distribution))

    if not os.path.exists(Package_filename):
        print("ERROR: activation package failed for distribution %s" % Distribution)
    else:
        shutil.move(Package_filename, Package_destination)
        Sign_rpm_package(Package_destination)

    # Clean
    for File in [Package_filename, Repo_filename, Spec_filename, Key_filename]:
        if os.path.exists(File):
            os.remove(File)

#
# Create_repo_deb - create repo activation package
def Create_repo_deb(Path, Repo, Distribution, Release = False):
    Control_file = Configuration["Repo_control_template"].replace("REPO_NAME", Repo)
    Control_file = Control_file.replace("DISTRIBUTION", Distribution)

    List_file = "deb %s/deb/%s %s main" % (Configuration["Repo_url"], os.path.basename(Path), Distribution)

    Build_root = "/tmp"
    Build_dir = "repo-" + Repo + "-1.0-1" + Distribution.replace("-snapshots", "") + "_all"

    if os.path.exists(os.path.join(Build_root, Build_dir)):
        shutil.rmtree(os.path.join(Build_root, Build_dir))

    os.makedirs(os.path.join(Build_root, Build_dir))
    os.makedirs(os.path.join(Build_root, Build_dir, "DEBIAN"))
    os.makedirs(os.path.join(Build_root, Build_dir, "etc"))
    os.makedirs(os.path.join(Build_root, Build_dir, "etc", "apt"))
    os.makedirs(os.path.join(Build_root, Build_dir, "etc", "apt", "sources.list.d"))
    os.makedirs(os.path.join(Build_root, Build_dir, "etc", "apt", "trusted.gpg.d"))

    Control_filename = os.path.join(Build_root, Build_dir, "DEBIAN", "control")
    List_filename = os.path.join(Build_root, Build_dir, "etc", "apt", "sources.list.d", Repo + ".list")
    Key_filename = os.path.join(Build_root, Build_dir, "etc", "apt", "trusted.gpg.d", Repo + ".gpg")

    # Add Control file
    Destination = open(Control_filename, "w")
    Destination.write(Control_file)
    Destination.close()

    # Add list file
    Destination = open(List_filename, "w")
    Destination.write(List_file)
    Destination.close()

    # Add key
    shutil.copy(os.path.join(Path, "keyring.gpg"), Key_filename)

    # Make deb package
    Command = ["dpkg-deb", "--build", os.path.join(Build_root, Build_dir)]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    if not os.path.exists(os.path.join(Build_root, Build_dir) + ".deb"):
        print("ERROR: activation package failed for distribution %s" % Distribution)
    else:
        shutil.move(os.path.join(Build_root, Build_dir) + ".deb", os.path.join(Path, Build_dir) + ".deb" )

    # Clean
    shutil.rmtree(os.path.join(Build_root, Build_dir))

#
# Add_rpm_package - add package to his repository, create the repository if don't exist 
#
def Add_rpm_package(Package, Name, Version, Arch, Distribution, Release = False):
    Package_directory = os.path.join(Configuration["Repo_path"], "rpm",
    "releases" if Release else "snapshots", Distribution, Arch, "RPMS")

    Package_name = os.path.basename(Package)

    if not os.path.exists(Package_directory):
        os.makedirs(Package_directory)
    else:
        # Clean old packages
        for File in os.listdir(Package_directory):
            if re.match(Package_name.rsplit("-", 1)[0] + "-[0-9\.]\..*\.rpm", File):
                os.remove(os.path.join(Package_directory, File))

    # Import rpm
    Package_final = os.path.join(Package_directory, Package_name.replace(Distribution,
                                    Distribution +  "." + Configuration["Repo_name"]))

    shutil.copyfile(Package, Package_final)
    Sign_rpm_package(Package_final)

    # Update repository
    Command = ["createrepo", "--update", os.path.join(Package_directory, "..")]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    # Sign repository
    Command = [ "gpg", "-s", "-b", "--batch", "--yes", "--armor", "--passphrase-file", 
                Configuration["Repo_key"]["passfile"], "-u", Configuration["Repo_key"]["key"],
                os.path.join(Package_directory, "..", "repodata", "repomd.xml")
              ]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    # Create activation package if needed
    if fnmatch.fnmatch(Distribution, "CentOS_*") \
       or fnmatch.fnmatch(Distribution, "RHEL_*") \
       or fnmatch.fnmatch(Distribution, "Fedora_*"):
        Repo = Configuration["Repo_name"]
        if not Release:
            Repo += "-snapshots"

        Distribution_path = os.path.normpath(os.path.join(Package_directory, "..", ".."))
        Distribution_file = "repo-%s-1.0.%s.noarch.rpm" % (Repo, Distribution)

        if not os.path.isfile(os.path.join(Distribution_path, Distribution_file)):
            Create_repo_rpm(Distribution_path, Repo, Distribution, Release)

#
# Add_deb_package - add package to his repository, create the repository if don't exist.
#
def Add_deb_package(Package, Name, Version, Arch, Distribution, Release = False):
    Dest = "Debian" if fnmatch.fnmatch(Distribution, "Debian_*") else "Ubuntu"
    Arch = "amd64" if Arch == "x86_64" else "i386"

    if not Configuration[Dest + "_names"].has_key(Distribution):
        print("ERROR: unable to import package %s, unknown distribution %s" % (Package, Distribution))
        return

    Dist = Configuration[Dest + "_names"][Distribution]
    if not Release:
        Dist += "-snapshots"

    Cache_directory = os.path.join(Configuration["Repo_path"], "deb", Dest.lower())
    Lib_directory = os.path.join(Cache_directory, "conf", "lib")
    Deb_directory = os.path.join(Lib_directory, "apt", Dist)

    if not os.path.exists(Lib_directory):
        os.makedirs(Lib_directory)

        Freight_conf_file = open(os.path.join(Cache_directory, "conf", "freight.conf"), "w")
        Freight_conf = Configuration["Freight_conf_template"]
        Freight_conf = Freight_conf.replace("CACHE_DIR", Cache_directory)
        Freight_conf = Freight_conf.replace("LIB_DIR", Lib_directory)
        Freight_conf_file.write(Freight_conf)
        Freight_conf_file.close()
    else:
        # Clean old packages
        if fnmatch.fnmatch(Name, "*-doc"):
            map(os.remove, glob(os.path.join(Deb_directory, "%s_*%s.deb" % (Name, Distribution))))
        else:
            map(os.remove, glob(os.path.join(Deb_directory, "%s_*%s.%s.deb" % (Name, Arch, Distribution))))

    # Import deb file
    Command = [ "freight-add", "-c", os.path.join(Cache_directory, "conf", "freight.conf"),
                Package, "apt/" + Dist
              ]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    # Update repository
    Command = [ "freight-cache", "-c", os.path.join(Cache_directory, "conf", "freight.conf"),
                "-g", Configuration["Repo_key"]["key"],
                "-p", Configuration["Repo_key"]["passfile"],
                "apt/" + Dist
              ]
    subprocess.call(Command, stdout=NULLOUT, stderr=NULLOUT)

    # Create activation package if needed
    Repo = Configuration["Repo_name"]
    if not Release:
        Repo += "-snapshots"

    Distribution_file = "repo-%s-1.0-1%s_all.deb" % (Repo, Configuration[Dest + "_names"][Distribution])

    if not os.path.isfile(os.path.join(Cache_directory, Distribution_file)):
        Create_repo_deb(Cache_directory, Repo, Dist, Release)

#
# Main
#

NULLOUT= open(os.devnull, 'w')

# Read configuration

Configuration = {}
execfile( os.path.join(os.path.dirname(os.path.realpath(__file__)), "Repo.conf"), Configuration)

