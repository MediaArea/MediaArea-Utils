#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import time
import fnmatch
import argparse
import traceback
import importlib
import subprocess

import xml.etree.ElementTree as ElementTree

class HandleOBSResults:
    def __init__(self) -> None:
        self.config = {}
        self.plugins = {}
        self.project = {}
        self.packages = {}
        self.distributions = {}

        # read configuration
        basedir = os.path.dirname(os.path.realpath(__file__))
        confdir = os.path.join(basedir, 'conf')

        if os.path.exists(os.path.join(confdir, 'dist.conf')):
            with open(os.path.join(confdir, 'dist.conf'), 'r') as h:
                exec(h.read(), None, self.config)

        if os.path.exists(os.path.join(confdir, 'local.conf')):
            with open(os.path.join(confdir, 'local.conf'), 'r') as h:
                exec(h.read(), None, self.config)

        # placeholder for runtime configuration
        self.config['runtime'] = {}

        # parse commandline
        parser = argparse.ArgumentParser()
        parser.add_argument('--release', action='store_true', help='release mode')
        parser.add_argument('--filter', help='filter to distribution[/arch][,...]')
        parser.add_argument('repository')
        parser.add_argument('project')
        parser.add_argument('version')
        parser.add_argument('destination')
        parser.add_argument('subdirectory')
        arguments = parser.parse_args()

        self.config['runtime']['release'] = arguments.release
        self.config['runtime']['repository'] = arguments.repository
        if arguments.project not in self.config.get('projects', {}):
            self.fatal(f"unknown project '{arguments.project}'")
        self.config['runtime']['project'] = arguments.project
        self.config['runtime']['version'] = arguments.version
        self.config['runtime']['destination'] = arguments.destination
        self.config['runtime']['subdirectory'] = arguments.subdirectory

        # fetch and filter distributions
        result, output = self.run_command(f"osc results --xml {self.config['runtime']['repository']}/{self.config['runtime']['project']}")
        if not result:
            self.fatal('unable to fetch distributions list')

        root = ElementTree.fromstring(output)
        for element in root.iter('result'):
            dist = element.attrib.get('repository', '')
            arch = element.attrib.get('arch', '')
            if dist and arch:
                self.distributions[dist] = self.distributions.get(dist, []) + [arch]

        if arguments.filter:
            filtered = {}
            for element in arguments.filter.split(','):
                dist = element.split('/')[0].strip()
                if len(element.split('/')) > 1:
                    arch = element.split('/')[1].strip()
                    if arch not in filtered.get(dist, []):
                        filtered[dist] = filtered.get(dist, []) + [arch]
                else:
                    filtered[dist] =  self.distributions.get(dist)
            self.distributions = filtered

        self.project = {
            'name': self.config['runtime']['project'],
            'short': self.config.get('projects', {}).get(self.config['runtime']['project'], {}).get('short', ''),
            'version': self.config['runtime']['version'],
            'release': self.config['runtime']['release']
        }

        self.packages = self.config.get('projects').get(self.config['runtime']['project'], {}).get('packages', {})

        # load plugins
        for name, conf in self.config.get('plugins', {}).items():
            if conf.get('enabled', False):
                plugin = importlib.import_module(f"plugins.{name}")
                self.plugins[name] = plugin.HandleOBSResultsPlugin(self.project, self.packages, conf.get('conf', {}), self.info, self.error)

        # start main loop
        self.waiting_loop()

    def info(self, message: str, sender: str = '') -> None:
        for _, plugin in self.plugins.items():
            plugin.info(message, sender)
        print(f"info{f'({sender})' if sender else ''}: {message}")
        sys.stdout.flush()

    def error(self, message: str, sender: str = '') -> None:
        for _, plugin in self.plugins.items():
            plugin.error(message, sender)
        print(f"error{f'({sender})' if sender else ''}: {message}", file=sys.stderr)
        sys.stderr.flush()

    def fatal(self, message: str, sender: str = '') -> None:
        for _, plugin in self.plugins.items():
            plugin.fatal(message, sender)
        print(f"fatal{f'({sender})' if sender else ''}: {message}", file=sys.stderr)
        sys.stderr.flush()
        sys.exit(1)

    def build_status(self, dist: str, arch: str, status: str) -> None:
        for _, plugin in self.plugins.items():
            plugin.build_status(dist, arch, status)

    def package_downloaded(self, dist: str, arch: str, package: str, filename: str, filepath: str, plugins_conf: object) -> None:
        self.info(f"downloaded '{dist}/{arch}/{filename}'")
        for name, plugin in self.plugins.items():
            plugin.package_downloaded(dist, arch, package, filename, filepath, plugins_conf.get(name, {}))

    def run_command(self, command: str) -> (bool, str):
        result = True
        output = ''
        try:
            output = subprocess.check_output(command, stderr=subprocess.STDOUT, shell=True).strip()
        except:
            result = False

        return (result, output)

    def download_packages(self, dist: str, arch: str, distinfo: object, buildinfo: object, pkgsinfo: object) -> None:
        for package in self.packages:
            if any(re.match(d, dist) for d in package.get('exclude', [])):
                continue

            name_short = (
                f"{package.get('name', '')}"
                f"{distinfo.get('libsuffix', '') if package.get('kind', '') == 'lib' or (package.get('kind', '') == 'dbg' and package.get('name', '').startswith('lib')) else ''}"
                f"{'v5' if (package.get('kind', '') == 'lib' or package.get('kind', '') == 'dbg') and distinfo.get('format', {}).get('extension', '') == 'deb' and package.get('v5suffix', False) else ''}"
                f"{distinfo.get('format', {}).get('docsuffix', '') if package.get('kind', '') == 'doc' else ''}"
                f"{distinfo.get('format', {}).get('devsuffix', '') if package.get('kind', '') == 'dev' else ''}"
                f"{distinfo.get('format', {}).get('debugsuffix', '') if package.get('kind', '') == 'dbg' else ''}"
            )

            name_dist = (
                f"{name_short}"
                f"{distinfo.get('format', {}).get('separator1', '-')}"
                f"{self.config['runtime']['version']}-*"
                f"{distinfo.get('format', {}).get('separator2', '-')}"
                f"{distinfo.get('format', {}).get(arch, arch) if not package.get('universal', False) else distinfo.get('format', {}).get('noarch', 'noarch')}."
                f"{distinfo.get('format', {}).get('extension', '')}"
            )

            name_local = (
                f"{name_short}"
                f"{distinfo.get('format', {}).get('separator1', '-')}"
                f"{self.config['runtime']['version']}"
                f"{distinfo.get('format', {}).get('revision', '')}"
                f"{distinfo.get('format', {}).get('separator2', '-')}"
                f"{distinfo.get('format', {}).get(arch, arch)}"
                f".{dist}."
                f"{distinfo.get('format', {}).get('extension', '')}"
            )

            binary_found = False;
            for binary in pkgsinfo.findall('binary'):
                if fnmatch.fnmatch(binary.attrib.get('filename', ''), name_dist):
                    name_dist = binary.attrib.get('filename', '')
                    binary_found = True
                    break

            if not binary_found:
                self.error(f"missing package '{name_dist}' for '{dist}/{arch}'")
                continue

            dest = (
                f"{self.config['runtime'].get('destination', '')}"
                f"{os.path.sep}"
                f"{package.get('dest', '')}"
                f"{os.path.sep}"
                f"{self.config['runtime'].get('subdirectory', '')}"
            )

            if not os.path.exists(dest):
                try:
                    os.makedirs(dest)
                except:
                    self.fatal(f"unable to create '{dest}'")

            try:
                os.remove(os.path.join(dest, name_dist))
                os.remove(os.path.join(dest, name_local))
            except:
                pass

            result, _ = self.run_command(f"osc getbinaries --debug -q -d '{dest}' {self.config['runtime']['repository']} {self.config['runtime']['project']} {dist} {arch} {name_dist}")
            if not result:
                self.error(f"download failed for '{dist}/{arch}/{name_dist}'")
                try:
                    os.remove(os.path.join(dest, name_dist))
                except:
                    pass
                continue

            try:
                os.rename(os.path.join(dest, name_dist), os.path.join(dest, name_local))
            except:
                self.error(f"download failed for '{dist}/{arch}/{name_dist}'")
                try:
                    os.remove(os.path.join(dest, name_dist))
                except:
                    pass
                continue

            self.package_downloaded(dist, arch, name_short, name_local, dest, package.get('plugins', {}))

    def check_status(self) -> None:
        result, output = self.run_command(f"osc results --xml {self.config['runtime']['repository']}/{self.config['runtime']['project']}")
        if not result:
            self.error('unable to fetch build statuses')
            return

        root = ElementTree.fromstring(output)
        for dist, archs in dict(self.distributions).items():
            distinfo = next((d for n, d in self.config.get('distinfos', {}).items() if re.match(n, dist)), None)
            if distinfo is None:
                self.error(f"unknown distribution '{dist}'")
                del self.distributions[dist]
                continue

            for arch in list(archs):
                result = root.find(f"./result[@repository='{dist}'][@arch='{arch}']/status[@package='{self.config['runtime']['project']}']")
                if result is None:
                    self.error(f"missing status for '{dist}/{arch}'")
                    continue
                elif result.get('code') == 'succeeded':
                    self.info(f"build succeeded for '{dist}/{arch}', downloading packages...")

                    result, output = self.run_command(f"osc api /build/{self.config['runtime']['repository']}/{dist}/{arch}/{self.config['runtime']['project']}/_buildenv")
                    if not result:
                        self.error(f"unable to fetch build informations for '{dist}/{arch}'")
                        continue
                    buildinfo = ElementTree.fromstring(output)

                    result, output = self.run_command(f"osc api /build/{self.config['runtime']['repository']}/{dist}/{arch}/{self.config['runtime']['project']}")
                    if not result:
                        self.error("unable to fetch packages list for '{dist}/{arch}'")
                        continue
                    pkgsinfo = ElementTree.fromstring(output)

                    self.download_packages(dist, arch, distinfo, buildinfo, pkgsinfo)
                    self.distributions[dist].remove(arch)
                elif result.get('code') == 'excluded' or result.get('code') == 'disabled':
                    self.distributions[dist].remove(arch)
                elif result.get('code') == 'broken' or result.get('code') == 'unresolvable' or result.get('code') == 'failed':
                    self.error(f"build {result.get('code')} for '{dist}/{arch}'")
                    self.distributions[dist].remove(arch)

                self.build_status(dist, arch, result)

            if not self.distributions[dist]:
                del self.distributions[dist]

    def timeout(self) -> None:
        for _, plugin in self.plugins.items():
            plugin.timeout()

    def finish(self) -> None:
        for _, plugin in self.plugins.items():
            plugin.finish()

    def waiting_loop(self) -> None:
        count = 0
        while count < 24:
            count += 1

            # wait 1mn before the first check to avoid outdated results
            if count == 1:
                self.info('wait 10mn...')
                time.sleep(600)

            self.check_status()
            if not self.distributions:
                break

            # at first, check every 10mn during 3h, then every 20mn during 1h
            self.info(f"all builds aren’t finished yet, wait another 10mn...")
            time.sleep(600)

        # we have wait for 4h
        if count == 24:
            self.error('timeout')

HandleOBSResults()

