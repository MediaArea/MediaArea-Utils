#!/usr/bin/env python
# -*- coding: utf-8 -*-

from . import base

import os
import subprocess

class HandleOBSResultsPlugin(base.HandleOBSResultsPlugin):
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        super().__init__(project, packages, conf, info, error)
        self.name = 'sign'
        self.plugin_info('loaded')

    def sign_rpm(self, package_path: str) -> bool:
        key = self.config.get('key', '')
        passfile = self.config.get('passfile', '')

        command = [
            'rpm', '--addsign',
            '--define', f'%_gpg_name {key}',
            '--define', f'%_gpg_sign_cmd_extra_args --pinentry-mode loopback --passphrase-file={passfile}',
            package_path
        ]

        return self.run_sign_command(command, os.path.basename(package_path), 'RPM')

    def sign_arch(self, package_path: str) -> bool:
        key = self.config.get('key', '')
        passfile = self.config.get('passfile', '')

        command = [
            'gpg', '--batch', '--yes', '--detach-sign',
            '--pinentry-mode', 'loopback',
            '--passphrase-file', passfile,
            '-u', key,
            '--output', f'{package_path}.sig',
            package_path
        ]

        return self.run_sign_command(command, os.path.basename(package_path), 'Arch')

    def run_sign_command(self, command: object, filename: str, package_type: str) -> bool:
        try:
            result = subprocess.run(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )
        except (OSError, subprocess.SubprocessError) as exception:
            self.plugin_error(f"unable to sign {package_type} package '{filename}': {exception}")
            return False

        if result.returncode != 0:
            output = result.stdout.strip()
            self.plugin_error(f"unable to sign {package_type} package '{filename}'{f': {output}' if output else ''}")
            return False

        return True

    def package_downloaded(self, dist: str, arch: str, package: str, filename: str, filepath: str, plugin_conf: object) -> None:
        package_path = os.path.join(filepath, filename)
        lower_filename = filename.lower()

        # Debian repositories are signed through their metadata, not individual packages.
        if not lower_filename.endswith('.rpm') and not lower_filename.endswith('.pkg.tar.zst'):
            return

        if not self.config.get('key', '') or not self.config.get('passfile', ''):
            self.plugin_error("unable to sign package: 'key' and 'passfile' must be configured")
            return

        if lower_filename.endswith('.rpm'):
            success = self.sign_rpm(package_path)
        else:
            success = self.sign_arch(package_path)

        if success:
            self.plugin_info(f"signed package '{filename}'")
