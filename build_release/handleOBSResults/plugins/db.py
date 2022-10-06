#!/usr/bin/env python
# -*- coding: utf-8 -*-

from . import base

import mysql.connector

class HandleOBSResultsPlugin(base.HandleOBSResultsPlugin):
    def __init__(self, project: object, packages: object, conf: object, info: object, error: object) -> None:
        super().__init__(project, packages, conf, info, error)
        self.name = 'db'
        self.plugin_info('loaded')

        self.status_table = f"{'releases' if self.project.get('release', False) else 'snapshots'}_obs_{self.project.get('short', '')}"
        self.dlpages_table = f"releases_dlpages_{self.project.get('short', '')}"

        try:
            with mysql.connector.connect(**self.config) as db:
                db.autocommit = True
                with db.cursor() as cur:
                    # create table or clean status table
                    cur.execute(f"SELECT * FROM information_schema.tables WHERE table_schema='{db.database}' AND table_name='{self.status_table}';")
                    if cur.fetchone() is None:
                        cur.execute(f"CREATE TABLE IF NOT EXISTS `{self.status_table}` (distrib varchar(50), arch varchar(10), state tinyint(4)) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;")
                    else:
                        cur.execute(f"TRUNCATE TABLE `{self.status_table}`;")

                    # create dlpages table if not exists
                    if self.project.get('release', False):
                        cur.execute(f"SELECT * FROM information_schema.tables WHERE table_schema='{db.database}' AND table_name='{self.dlpages_table}';")
                        if cur.fetchone() is None:
                            cur.execute(f"CREATE TABLE IF NOT EXISTS `{self.dlpages_table}` (platform varchar(50), arch varchar(10), version varchar(18)) DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;")
        except:
            self.plugin_error('unable initialize database')

    def build_status(self, dist: str, arch: str, status: str) -> None:
        if status == 'excluded' or status == 'disabled':
            state = 0
        elif status == 'succeeded':
            state = 1
        elif status =='scheduled' or status == 'building':
            state = 2
        elif status == 'broken' or status == 'unresolvable' or status == 'failed':
            state = 2
        else:
            state = 3

        try:
            with mysql.connector.connect(**self.config) as db:
                db.autocommit = True
                with db.cursor() as cur:
                    # check if row exists
                    cur.execute(f"SELECT * FROM `{self.status_table}` WHERE distrib='{dist}' AND arch='{arch}';")
                    if cur.fetchone() is None:
                        cur.execute(f"INSERT INTO `{self.status_table}` (distrib, arch, state) VALUES ('{dist}', '{arch}', {state});")
                    else:
                        cur.execute(f"UPDATE `{self.status_table}` SET state='{state}' WHERE distrib='{dist}' AND arch='{arch}';")

                    success = True
        except:
            self.plugin_error('unable to save state to database')

    def package_downloaded(self, dist: str, arch: str, package: str, filename: str, filepath: str, plugin_conf: object) -> None:
        version = self.project.get('version', '')
        column = plugin_conf.get('name')
        if column is None:
            return

        success =  False
        try:
            with mysql.connector.connect(**self.config) as db:
                db.autocommit = True
                with db.cursor() as cur:
                    # check if row exists
                    cur.execute(f"SELECT * FROM `{self.dlpages_table}` WHERE platform='{dist}' AND arch='{arch}';")
                    if cur.fetchone() is None:
                        cur.execute(f"INSERT INTO `{self.dlpages_table}` (platform, arch, version) VALUES ('{dist}', '{arch}', '{version}');")
                    else:
                        cur.execute(f"UPDATE `{self.dlpages_table}` SET version='{version}' WHERE platform='{dist}' AND arch='{arch}';")

                    # check if column exists
                    cur.execute(f"SELECT * FROM information_schema.columns WHERE table_schema = '{db.database}' AND table_name = '{self.dlpages_table}' AND column_name = '{column}';")
                    if cur.fetchone() is None:
                        cur.execute(f"ALTER TABLE `{self.dlpages_table}` ADD `{column}` VARCHAR(120) DEFAULT '';")

                    cur.execute(f"UPDATE `{self.dlpages_table}` SET `{column}`='{filename}' WHERE platform='{dist}' AND arch='{arch}';")
        except:
            self.plugin_error('unable to save state to database')
