"""
Diamond collector that publishes sizes for all directories that match a glob pattern,
to track growth over time
"""
from glob import glob

import diamond.collector
import os
import re
import shlex
import subprocess


class DirectorySizeCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        config_help = super(DirectorySizeCollector, self).get_default_config_help()
        config_help.update({
            'base_glob_list': 'List of globs to match directories to track size for '
                         'e.g. /srv/misc/shared/*/home',
            'base_glob_exclude': 'Exclude directories that match this string '
                                 'e.g. /tools/',
            'build_prefix_from_dir_path': 'Build metric prefix using the directory path '
                                          'Default: False',
            'build_prefix_depth': 'The last n components of the directory path are '
                                  'concanetenated to build prefix, where n is the '
                                  'build_prefix_depth. e.g. build_prefix_depth:2, '
                                  'for path /srv/misc/shared/bots/home - yeilds prefix '
                                  'bots.home',
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(DirectorySizeCollector, self).get_default_config()
        config.update({
            'base_glob_list': [],
            'base_glob_exclude': '',
            'build_prefix_from_dir_path': False,
            'build_prefix_depth': None,
        })
        return config

    def directory_size(self, directory):
        """
        Return directory size in kilobytes
        """
        size = None
        if os.path.isdir(directory):
            try:
                size = subprocess.check_output(shlex.split('timeout 10m nice -n 19 ionice -c 3 \
                    du -k -s {}'.format(directory))).decode('utf-8').split('\t')[0]
            except subprocess.CalledProcessError as e:
                print("du failed for directory {}".format(directory), e)
        return size

    def directories(self, glob_path):
        """
        Return list of directory names that match the glob_path, excluding
        any that match with base_glob_exclude
        """
        if self.config['base_glob_exclude']:
            dir_paths = [path for path in glob(glob_path)
                         if self.config['base_glob_exclude'] not in path]
        else:
            dir_paths = glob(glob_path)
        return dir_paths

    def prefix_from_dir_path(self, path):
        """
        Build prefix for metric from last n parts of path (separated by /),
        where n = self.config['build_prefix_depth']
        """
        depth = self.config['build_prefix_depth']
        components = [component for component in path.split('/') if component]
        return '.'.join(components[-depth:])

    def collect(self):
        """
        Publish directory sizes in kilobytes
        """
        for glob_path in self.config['base_glob_list']:
            for directory in self.directories(glob_path):
                size = self.directory_size(directory)
                if size:
                    if(self.config['build_prefix_from_dir_path']):
                        self.publish_gauge('{}.size'.format(
                            self.prefix_from_dir_path(directory)), size)
                    else:
                        self.publish_gauge('size', size)
