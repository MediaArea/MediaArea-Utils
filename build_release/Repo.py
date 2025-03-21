from glob import glob

import subprocess
import datetime
import os.path
import fnmatch
import pexpect
import shutil
import sys
import os
import re

#
# Sign_rpm_package - sign the given rpm with the configured key
#
def Sign_rpm_package(Package):
    Command = ["rpm", "--addsign",
               "--define", "%%_gpg_name %s" % Configuration["Repo_key"]["key"],
               "--define", "%%_gpg_sign_cmd_extra_args --pinentry-mode loopback --passphrase-file=%s" % Configuration["Repo_key"]["passfile"],
               Package]

    if subprocess.call(Command, stdout=OUT, stderr=OUT) != 0:
        print("ERROR: unable to sign rpm package %s" % Package)

#
# Create_repo_rpm - create repo activation package
#
def Create_repo_rpm(Path, Repo, Release = False):
    Version = Configuration["Repo_version"]

    Repo_url = os.path.join(Configuration["Repo_url"], "rpm", "releases" if Release else "snapshots")

    Repo_spec_template = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "rpm_spec_template"), "r")
    Repo_spec = Repo_spec_template.read()
    Repo_spec_template.close()

    Repo_spec = Repo_spec.replace("REPO_NAME", Repo)
    Repo_spec = Repo_spec.replace("REPO_URL", Repo_url)
    Repo_spec = Repo_spec.replace("PKG_VERSION", Version.split("-")[0])
    Repo_spec = Repo_spec.replace("PKG_RELEASE", Version.split("-")[1])
    Repo_spec = Repo_spec.replace("DATE", datetime.date.today().strftime("%a %b %d %Y"))

    Command = ["gpg", "--export", "--armor", "-u", Configuration["Repo_key"]["key"]]
    Repo_spec = Repo_spec.replace("REPO_KEY", subprocess.check_output(Command))

    Build_root = os.path.join(os.getenv("HOME"), "rpmbuild")

    for Directory in ["BUILD", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
            if not os.path.exists(os.path.join(Build_root, Directory)):
                os.makedirs(os.path.join(Build_root, Directory))

    # Clean buildroot
    Package_filename = os.path.join(Build_root, "RPMS", "noarch", "repo-%s-%s.noarch.rpm" % (Repo, Version))
    Spec_filename = os.path.join(Build_root, "SPECS", "repo-%s.spec" % Repo)

    for File in [Package_filename, Spec_filename]:
        if os.path.exists(File):
            os.remove(File)

    # Add spec file
    Destination = open(Spec_filename, "w")
    Destination.write(Repo_spec)
    Destination.close()

    # Make rpm package
    Command = ["rpmbuild", "-bb", Spec_filename,
               "--define", "%_source_filedigest_algorithm 0",
               "--define", "%_binary_filedigest_algorithm 0",
               "--define", "%_source_payload w0.bzdio",
               "--define", "%_binary_payload w0.bzdio"]
    subprocess.call(Command, stdout=OUT, stderr=OUT)

    Package_destination = os.path.join(Path, "repo-%s-%s.noarch.rpm" % (Repo, Version))

    if not os.path.exists(Package_filename):
        print("ERROR: rpm activation package failed")
    else:
        shutil.move(Package_filename, Package_destination)
        Sign_rpm_package(Package_destination)

    # Clean
    for File in [Package_filename, Spec_filename]:
        if os.path.exists(File):
            os.remove(File)

#
# Create_repo_deb - create repo activation package
#
def Create_repo_deb(Path, Repo, Release = False):
    Version = Configuration["Repo_version"]

    Install_file = "%s.gpg   /usr/share/%s" % (Repo, Repo)

    Changelog_file_template = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_changelog_template"), "r")
    Changelog_file = Changelog_file_template.read()
    Changelog_file_template.close

    Changelog_file = Changelog_file.replace("REPO_NAME", Repo)
    Changelog_file = Changelog_file.replace("VERSION_FULL", Version)

    Control_file_template = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_control_template"), "r")
    Control_file = Control_file_template.read()
    Control_file_template.close()

    Control_file = Control_file.replace("REPO_NAME", Repo)
    Control_file = Control_file.replace("VERSION_FULL", Version)

    Postinst_file_template = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_postinst_template"), "r")
    Postinst_file =  Postinst_file_template.read()
    Postinst_file_template.close()

    Debian_releases = ""
    for Debian_version, Debian_codename in Configuration["Debian_names"]:
        Debian_releases = Debian_releases + "," if Debian_releases else ""

        if "." in Debian_version:
            Debian_releases = Debian_releases + re.split('_|\.', Debian_version)[-2] + ":"
        else:
            Debian_releases = Debian_releases + re.split('_', Debian_version)[-1] + ":"

        Debian_releases = Debian_releases + Debian_codename

    Ubuntu_releases = ""
    for Ubuntu_version, Ubuntu_codename in Configuration["Ubuntu_names"]:
        Ubuntu_releases = Ubuntu_releases + "," if Ubuntu_releases else ""

        Ubuntu_releases = Ubuntu_releases + Ubuntu_version.split('_')[-1].upper() + ":"

        Ubuntu_releases = Ubuntu_releases + Ubuntu_codename

    Raspbian_releases = ""
    for Raspbian_version, Raspbian_codename in Configuration["Raspbian_names"]:
        Raspbian_releases = Raspbian_releases + "," if Raspbian_releases else ""

        if "." in Raspbian_version:
            Raspbian_releases = Raspbian_releases + re.split('_|\.', Raspbian_version)[-2] + ":"
        else:
            Raspbian_releases = Raspbian_releases + re.split('_', Raspbian_version)[-1] + ":"

        Raspbian_releases = Raspbian_releases + Raspbian_codename

    Postinst_file = Postinst_file.replace("REPO_NAME", Repo)
    Postinst_file = Postinst_file.replace("DEBIAN_RELEASES", Debian_releases)
    Postinst_file = Postinst_file.replace("UBUNTU_RELEASES", Ubuntu_releases)
    Postinst_file = Postinst_file.replace("RASPBIAN_RELEASES", Raspbian_releases)
    Postinst_file = Postinst_file.replace("REPO_URL", Configuration["Repo_url"])
    Postinst_file = Postinst_file.replace("SNAPSHOT", "" if Release else "-snapshots")

    Postrm_file_template = open(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_postrm_template"), "r")
    Postrm_file = Postrm_file_template.read()
    Postrm_file_template.close()

    Postrm_file = Postrm_file.replace("REPO_NAME", Repo)

    Compat_file = "5"

    Build_root = "/tmp"
    Build_dir = "repo-%s_%s_all" % (Repo, Version)

    if os.path.exists(os.path.join(Build_root, Build_dir)):
        shutil.rmtree(os.path.join(Build_root, Build_dir))

    os.makedirs(os.path.join(Build_root, Build_dir))
    os.makedirs(os.path.join(Build_root, Build_dir, "debian"))

    Changelog_filename = os.path.join(Build_root, Build_dir, "debian", "changelog")
    Copyright_filename = os.path.join(Build_root, Build_dir, "debian", "copyright")
    Postinst_filename = os.path.join(Build_root, Build_dir, "debian", "postinst")
    Control_filename = os.path.join(Build_root, Build_dir, "debian", "control")
    Install_filename = os.path.join(Build_root, Build_dir, "debian", "install")
    Postrm_filename = os.path.join(Build_root, Build_dir, "debian", "postrm")
    Compat_filename = os.path.join(Build_root, Build_dir, "debian", "compat")
    Rules_filename = os.path.join(Build_root, Build_dir, "debian", "rules")
    Key_filename = os.path.join(Build_root, Build_dir, Repo + ".gpg")

    # Add changelog file
    Destination = open(Changelog_filename, "w")
    Destination.write(Changelog_file)
    Destination.close()

    # Add copyright file
    shutil.copy(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_copyright_template"), Copyright_filename)

    # Add control file
    Destination = open(Control_filename, "w")
    Destination.write(Control_file)
    Destination.close()

    # Add  postinst file
    Destination = open(Postinst_filename, "w")
    Destination.write(Postinst_file)
    Destination.close()
    os.chmod(Postinst_filename, 0755)

    # Add  postrm file
    Destination = open(Postrm_filename, "w")
    Destination.write(Postrm_file)
    Destination.close()
    os.chmod(Postrm_filename, 0775)

    # Add install file
    Destination = open(Install_filename, "w")
    Destination.write(Install_file)
    Destination.close()
    os.chmod(Install_filename, 0755)

    # Add compat file
    Destination = open(Compat_filename, "w")
    Destination.write(Compat_file)
    Destination.close()


    # Add rules
    shutil.copy(os.path.join(os.path.dirname(os.path.realpath(__file__)), "repo_templates", "deb_rules_template"), Rules_filename)

    # Add key
    shutil.copy(os.path.join(Path, "keyring.gpg"), Key_filename)

    # Make deb package
    Command = ["dpkg-buildpackage", "-rfakeroot", "-b", "-d", "-us", "-uc"]
    subprocess.call(Command, stdout=OUT, stderr=OUT, cwd=os.path.join(Build_root, Build_dir))

    if not os.path.exists(os.path.join(Build_root, Build_dir) + ".deb"):
        print("ERROR: deb activation package failed")
    else:
        shutil.move(os.path.join(Build_root, Build_dir) + ".deb", os.path.join(Path, "..", Build_dir) + ".deb" )

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
            if re.match(Package_name.rsplit("-", 1)[0] + "-[0-9\.]+(git)?\..*\.rpm", File):
                os.remove(os.path.join(Package_directory, File))

    # Import rpm
    Package_final = os.path.join(Package_directory, Package_name.replace(Distribution,
                                    Distribution +  "." + Configuration["Repo_name"]))

    shutil.copyfile(Package, Package_final)
    Sign_rpm_package(Package_final)

    # Create activation package if needed
    Repo = Configuration["Repo_name"]
    if not Release:
        Repo += "-snapshots"

    Activation_rpm_file = "repo-%s-%s.noarch.rpm" % (Repo, Configuration["Repo_version"])

    if not os.path.isfile(os.path.join(Package_directory, Activation_rpm_file)):
        # Remove old versions
        map(os.remove, glob(os.path.join(Package_directory, "repo-%s-*.noarch.rpm" % Repo)))

        if not os.path.isfile(os.path.join(Package_directory, "..", "..", "..", Activation_rpm_file)):
            Create_repo_rpm(os.path.normpath(os.path.join(Package_directory, "..", "..", "..")), Repo, Release)

        if os.path.isfile(os.path.join(Package_directory, "..", "..", "..", Activation_rpm_file)):
            shutil.copyfile(os.path.join(Package_directory, "..", "..", "..", Activation_rpm_file), os.path.join(Package_directory, Activation_rpm_file))

    # Update repository
    Command = ["createrepo_c", os.path.join(Package_directory, "..")]
    subprocess.call(Command, stdout=OUT, stderr=OUT)

    # Sign repository
    Command = [ "gpg", "-s", "-b", "--batch", "--yes", "--armor", "--passphrase-file", 
                Configuration["Repo_key"]["passfile"], "-u", Configuration["Repo_key"]["key"],
                os.path.join(Package_directory, "..", "repodata", "repomd.xml")
              ]
    subprocess.call(Command, stdout=OUT, stderr=OUT)

    # Export key if needed
    Key_filename = os.path.join(Package_directory, "..", "repodata", "repomd.xml.key")
    if not os.path.isfile(Key_filename):
        Command = ["gpg", "--export", "--armor", "-u", Configuration["Repo_key"]["key"], "--output", Key_filename]
        subprocess.call(Command, stdout=OUT, stderr=OUT)

#
# Add_deb_package - add package to his repository, create the repository if don't exist.
#
def Add_deb_package(Package, Name, Version, Arch, Distribution, Release = False):
    Dest = "Debian" if fnmatch.fnmatch(Distribution, "Debian_*") else "Raspbian" if fnmatch.fnmatch(Distribution, "Raspbian_*") else "Ubuntu"
    if len([item for item in Configuration[Dest + "_names"] if item[0] == Distribution]) == 0:
        print("ERROR: unable to import package %s, unknown distribution %s" % (Package, Distribution))
        return

    Dist = [item for item in Configuration[Dest + "_names"] if item[0] == Distribution][0][1]
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
        Freight_conf = Freight_conf.replace("KEY_NAME", Configuration["Repo_key"]["key"])
        Freight_conf = Freight_conf + "\n"
        if Dest=="Raspbian":
            Freight_conf = Freight_conf + "ARCHS=\"armhf arm64\""
        else:
            Freight_conf = Freight_conf + "ARCHS=\"i386 amd64 armhf arm64\""
        Freight_conf_file.write(Freight_conf)
        Freight_conf_file.close()
    else:
        # Clean old packages
        map(os.remove, glob(os.path.join(Deb_directory, "%s_*_%s.*.deb" % (Name, Deb_archs.get(Arch, Arch)))))

    # Import deb file
    Command = [ "freight-add", "-c", os.path.join(Cache_directory, "conf", "freight.conf"),
                Package, "apt/" + Dist
              ]
    subprocess.call(Command, stdout=OUT, stderr=OUT)

    # Create activation package if needed
    Repo = Configuration["Repo_name"].lower() + "" if Release else Configuration["Repo_name"].lower() + "-snapshots"

    Activation_deb_file = "repo-%s_%s_all.deb" % (Repo, Configuration["Repo_version"])

    if not os.path.isfile(os.path.join(Deb_directory, Activation_deb_file)):
        # Remove old versions
        map(os.remove, glob(os.path.join(Deb_directory, "repo-%s*_all.deb" % Repo)))

        if not os.path.isfile(os.path.join(Cache_directory, "..", Activation_deb_file)):
            Create_repo_deb(Cache_directory, Repo, Release)

        if os.path.isfile(os.path.join(Cache_directory, "..", Activation_deb_file)):
            Command = [ "freight-add", "-c", os.path.join(Cache_directory, "conf", "freight.conf"),
                        os.path.join(Cache_directory, "..", Activation_deb_file), "apt/" + Dist
                      ]
            subprocess.call(Command, stdout=OUT, stderr=OUT)

    # Update repository
    Command = [ "freight-cache", "-c", os.path.join(Cache_directory, "conf", "freight.conf"),
                "-g", Configuration["Repo_key"]["key"],
                "-p", Configuration["Repo_key"]["passfile"],
                "apt/" + Dist
              ]
    subprocess.call(Command, stdout=OUT, stderr=OUT)

#
# Main
#

# Read configuration

Configuration = {}
execfile(os.path.join(os.path.dirname(os.path.realpath(__file__)), "Repo_dist.conf"), Configuration)
if os.path.exists(os.path.join(os.path.dirname(os.path.realpath(__file__)), "Repo.conf")):
    execfile(os.path.join(os.path.dirname(os.path.realpath(__file__)), "Repo.conf"), Configuration)

# Output
if Configuration.get("log", False):
    OUT = open(os.devnull, 'w')
else:
    OUT = sys.stdout

# OBS to Debian archituctures map
Deb_archs = {
    "i586": "i386",
    "x86_64": "amd64",
    "armv7l": "armhf",
    "aarch64": "arm64"
}

# Command line invocation
if __name__ == "__main__":
    import argparse

    # always print commands output in interactive mode
    OUT = sys.stdout

    Args_parser = argparse.ArgumentParser()
    Args_parser.add_argument("package")
    Args_parser.add_argument("name")
    Args_parser.add_argument("arch")
    Args_parser.add_argument("distribution")
    Args_parser.add_argument("channel", choices=['release', 'snapshots'], default="release", nargs="?")
    Args = Args_parser.parse_args()

    Type = os.path.splitext(Args.package)[1]
    if Type == ".deb":
        Add_deb_package(Args.package, Args.name, 0, Args.arch, Args.distribution, True if Args.channel == "release" else False)
    elif Type == ".rpm":
        Add_rpm_package(Args.package, Args.name, 0, Args.arch, Args.distribution, True if Args.channel == "release" else False)
    else:
        print("ERROR: unknown filetype %s" % Type)
