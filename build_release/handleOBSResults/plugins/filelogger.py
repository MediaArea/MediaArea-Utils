#!/usr/bin/env python
# -*- coding: utf-8 -*-

from . import base

import sys

class HandleOBSResultsPlugin(base.HandleOBSResultsPlugin):
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        super().__init__(project, packages, conf, info, error)
        self.name = 'filelogger'

        # overwrite plugin_info and plugin_error to avoid infinite echo
        self.plugin_info = lambda message: (
            print(f"info({self.name}): {message}"),
            sys.stdout.flush()
        )

        self.plugin_error = lambda message: (
            print(f"info({self.name}): {message}"),
            sys.stdout.flush()
        )

        self.plugin_info('loaded')

    def info(self, message, sender: str = ''):
        if not self.config.get('log_info', False):
            return

        try:
            with open(self.config.get('log_info_path', 'info.log'), 'a') as output:
                output.write(f"info{f'({sender})' if sender else ''}: {message}\n")
        except:
            self.plugin_error('unable to write info log')

    def error(self, message, sender: str = ''):
        if not self.config.get('log_error', False):
            return

        try:
            with open(self.config.get('log_error_path', 'error.log'), 'a') as output:
                output.write(f"error{f'({sender})' if sender else ''}: {message}\n")
        except:
            self.plugin_error('unable to error info log')

    def fatal(self, message, sender: str = ''):
        if not self.config.get('log_fatal', False):
            return

        try:
            with open(self.config.get('log_fatal_path', 'fatal.log'), 'a') as output:
                output.write(f"fatal{f'({sender})' if sender else ''}: {message}\n")
        except:
            self.plugin_error('unable to write fatal log')
