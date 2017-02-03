"""
Diamond collector that publishes directory sizes for tools home and project
directories, to track growth over time
"""
import diamond.collector
import ldap3
import os
import shlex
import subprocess
import yaml


class ToolsNFSUsageCollector(diamond.collector.Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(ToolsNFSUsageCollector, self).get_default_config()
        config.update({
            'path_prefix': 'labstore',
            'hostname': 'labstore-secondary',
            'byte_unit': 'kilobyte',
            'tools_base_path': '/srv/tools/shared/tools',
        })
        return config

    def directory_size(self, directory):
        """
        Return directory size in kilobytes
        """
        if os.path.isdir(directory):
            size = subprocess.check_output(['du', '-s', directory]).decode(
                'utf-8').split('\t')[0]
            return size

    def tools_dirs(self, subdir):
        """
        Return list of directory names in TOOLS_PATH/subdir
        """
        dirs = subprocess.check_output(shlex.split('ls {}/{}'.format(
            self.config['tools_base_path'], subdir))).decode('utf-8').rstrip().split('\n')
        tool_dirs = [d for d in dirs if os.path.isdir('{}/{}/{}'.format(
            self.config['tools_base_path'], subdir, d))]
        return tool_dirs

    def project_dir(self, project):
        return '{}/project/{}'.format(self.config['tools_base_path'], project)

    def home_dir(self, user):
        return '{}/home/{}'.format(self.config['tools_base_path'], user)

    def collect(self):
        """
        Publish tools home and project directory sizes in kilobytes
        """
        for project in self.tools_dirs('project'):
            size = self.directory_size(self.project_dir(project))
            self.publish_gauge('tools.project.{}.size'.format(project), size)

        for user in self.tools_dirs('home'):
            size = self.directory_size(self.home_dir(user))
            self.publish_gauge('tools.home.{}.size'.format(user), size)
