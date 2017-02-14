"""
Diamond collector that publishes sizes for all directories that match a glob pattern,
to track growth over time
"""
from glob import glob

import diamond.collector
import os
import shlex
import subprocess


class DirectorySizeCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        config_help = super(DirectorySizeCollector, self).get_default_config_help()
        config_help.update({
            'dir_size_collector_config':
                '''
                List of dicts with optional keys:

                base_glob_pattern: Glob pattern to match directories to track size for
                                   e.g. /srv/misc/shared/*/home
                base_glob_exclude: Exclude directories that match this string e.g. /tools/
                build_prefix_from_dir_path: Build metric prefix using directory path (True/False)
                build_prefix_depth: The last n components of the directory path are
                                    concanetenated to build prefix, where n is the
                                    build_prefix_depth. e.g. build_prefix_depth:2,
                                    for path /srv/misc/shared/bots/home - yeilds 'bots.home'
                custom_prefix: Additional custom prefix. Resulting prefix will be
                               hostname + path_prefix + <custom_prefix> + <prefix_from_dir_path>
                '''
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(DirectorySizeCollector, self).get_default_config()
        config.update({
            'dir_size_collector_config': [
                {'base_glob_pattern': '',
                 'base_glob_exclude': '',
                 'build_prefix_from_dir_path': False,
                 'build_prefix_depth': None,
                 'custom_prefix': ''}
            ]
        })
        return config

    def directory_size(self, directory):
        """
        Return directory size in kilobytes
        """
        size = None
        if os.path.isdir(directory):
            try:
                size = subprocess.check_output(
                    shlex.split('/usr/bin/timeout 10m /usr/bin/nice -n 19 /usr/bin/ionice -c 3 \
                    /usr/bin/du -k -s {}'.format(directory))).decode('utf-8').split('\t')[0]
            except subprocess.CalledProcessError as e:
                print("du failed for directory {}".format(directory), e)
        return size

    def directories(self, glob_pattern, glob_exclude):
        """
        Return list of directory names that match the glob_pattern, excluding
        any that match with base_glob_exclude
        """
        if glob_exclude:
            dir_paths = [path for path in glob(glob_pattern) if glob_exclude not in path]
        else:
            dir_paths = glob(glob_pattern)
        return dir_paths

    def prefix_from_dir_path(self, path, depth):
        """
        Build prefix for metric from last n parts of path (separated by /),
        where n = self.config['build_prefix_depth']
        """
        if depth and depth > 0:
            components = [component for component in path.split('/') if component]
            return '.'.join(components[-depth:])
        return ''

    def prefix(self, config, directory):
        prefix_list = []
        if config.get('custom_prefix'):
            prefix_list.append(config['custom_prefix'])
        if(config.get('build_prefix_from_dir_path', False)):
            depth = config.get('build_prefix_depth')
            prefix_list.append(self.prefix_from_dir_path(directory, depth))
        prefix_list.append('size')
        return '.'.join(prefix_list)

    def collect(self):
        """
        Publish directory sizes in kilobytes
        """
        for config in self.config['dir_size_collector_config']:
            glob_pattern = config.get('base_glob_pattern', '')
            glob_exclude = config.get('base_glob_exclude', '')
            for directory in self.directories(glob_pattern, glob_exclude):
                size = self.directory_size(directory)
                if size:
                    self.publish_gauge(self.prefix(config, directory), size)
