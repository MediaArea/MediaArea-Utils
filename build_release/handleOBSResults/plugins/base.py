#!/usr/bin/env python
# -*- coding: utf-8 -*-

class HandleOBSResultsPlugin:
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        self.project = project
        self.packages = packages
        self.config = conf
        self.base_info = info
        self.base_error = error
        self.name = 'base'


    def plugin_info(self, message: str) -> None:
        self.base_info(message, self.name)

    def plugin_error(self, message: str) -> None:
        self.base_error(message, self.name)

    def info(self, message: str, sender: str = '') -> None:
        pass

    def error(self, message: str, sender: str = '') -> None:
        pass

    def fatal(self, message: str, sender: str = '') -> None:
        pass

    def build_status(self, dist: str, arch: str, status: str) -> None:
        pass

    def package_downloaded(self, dist: str, arch: str, package: str, filename: str, filepath: str, plugin_conf: object) -> None:
        pass
