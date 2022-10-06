#!/usr/bin/env python
# -*- coding: utf-8 -*-

from . import base

class HandleOBSResultsPlugin(base.HandleOBSResultsPlugin):
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        super().__init__(project, packages, conf, info, error)
        self.name = 'versioned'
        self.plugin_info('loaded')

        if project.get('name', '') == 'ZenLib':
            version3 = project.get('version', '').split('.')[:3]

            packages.append({
                'name': f"libzen{''.join(version3)}",
                'kind': 'lib',
                'dest': 'libzen0',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })

            packages.append({
                'name': f"libzen{''.join(version3)}",
                'kind': 'dev',
                'dest': 'libzen0',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })

            packages.append({
                'name': f"libzen{''.join(version3)}",
                'kind': 'doc',
                'dest': 'libzen0',
                'universal': True,
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })
        elif project.get('name', '') == 'MediaInfoLib':
            version2 = project.get('version', '').split('.')[:2]

            packages.append({
                'name': f"libmediainfo{''.join(version2)}",
                'kind': 'lib',
                'dest': 'libmediainfo0',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })

            packages.append({
                'name': f"libmediainfo{''.join(version2)}",
                'kind': 'dev',
                'dest': 'libmediainfo0',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })

            packages.append({
                'name': f"libmediainfo{''.join(version2)}",
                'kind': 'doc',
                'dest': 'libmediainfo0',
                'universal': True,
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })
        elif project.get('name', '') == 'MediaInfo':
            version2 = project.get('version', '').split('.')[:2]

            packages.append({
                'name': f"mediainfo{''.join(version2)}",
                'kind': 'bin',
                'dest': 'mediainfo',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })

            packages.append({
                'name': f"mediainfo{''.join(version2)}-gui",
                'kind': 'bin',
                'dest': 'mediainfo-gui',
                'exclude': ['^(?!(CentOS_)|(RHEL_)).*']
            })
