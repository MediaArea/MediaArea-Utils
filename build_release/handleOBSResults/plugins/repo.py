#!/usr/bin/env python
# -*- coding: utf-8 -*-

from . import base

import pathlib
import os

class HandleOBSResultsPlugin(base.HandleOBSResultsPlugin):
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        super().__init__(project, packages, conf, info, error)
        self.name = 'repo'
        self.plugin_info('loaded')

        self.output_script = self.config.get('output_script', 'repo_export.sh')
        self.repo_script = self.config.get('repo_script', 'Repo.py')

        try:
            os.remove(self.output_script)
        except:
            pass

        try:
            with open(self.output_script, 'a') as output:
                output.write('#!/bin/sh\n')
        except:
            self.plugin_error('unable create export script')

        os.chmod(self.output_script, 0o755)

    def package_downloaded(self, dist: str, arch: str, package: str, filename: str, filepath: str, plugin_conf: object) -> None:
        if pathlib.Path(filename).suffix != '.deb' and pathlib.Path(filename).suffix != '.rpm':
            return

        try:
            with open(self.output_script, 'a') as output:
                output.write(f"python2 {self.repo_script} {os.path.join(filepath, filename)} {package} {arch} {dist} {'release' if self.project.get('release', False) else 'snapshots'}\n")
        except:
            self.plugin_error(f"unable to add package '{filename}' to export script")
