# SPDX-License-Identifier: Apache-2.0
import os
import json
import subprocess
import wrapspawner

from traitlets import Dict, Bool, Unicode, List
from jupyterhub.app import JupyterHub
from jupyterhub.traitlets import EntryPointType
from jupyterhub.spawner import Spawner


class CondaEnvProfilesSpawner(wrapspawner.ProfilesSpawner):
    """
    Subclass of ProfilesSpawner that allows users to select from their
    conda enviroments to use for launching their jupyterhub singleuser server.
    """

    conda_cmd = List(
        default_value=['conda'],
        trait=Unicode(),
        help="""List of args to execute conda via subprocess.check_output.
        Set this to the args needed to properly launch conda for your user, perhaps
        sudoing with --set-home for the user.  This will be used to list out
        the existent conda environments for the user.
        """
    ).tag(config=True)

    # ProfilesSpawner is wrapping other Spawners, so we want to
    # reuse some traitlets defined by JupyterHub.  These will
    # be set for the spawner profiles that this CondaEnvProfilesSpawner will create.
    spawner_class = EntryPointType(
        default_value=JupyterHub.spawner_class.default_value,
        klass=JupyterHub.spawner_class.klass,
        entry_point_group=JupyterHub.spawner_class.entry_point_group,
        help=JupyterHub.spawner_class.help,
    ).tag(config=True)

    environment = Dict(
        help=Spawner.environment.help,
    ).tag(config=True)

    debug = Bool(
        default_value=False,
        help='If debug logging should be enabled for spawned profiles.'
    ).tag(config=True)

    conda_base_env_prefix = Unicode(
        default_value='/usr/lib/anaconda-wmf',
        help="""If set, this conda env is assumed to be a readonly base env.
        It can be configurably included or excluded form the list of available profiles
        with the include_conda_base_env_profile setting.
        """
    ).tag(config=True)

    include_conda_base_env_profile = Bool(
        default_value=True,
        help="""Whether to include a profile selection to spawn using the base conda env."""
    ).tag(config=True)

    jupyterhub_singleuser_conda_env_script = Unicode(
        default_value=os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            'jupyterhub-singleuser-conda-env.sh'
        ),
        help="""Path to a script that first sources a conda environment
        and then launches jupyterhub-singleuser from that environment.
        The path to the conda env to use will be provided as the first
        argument to this script.  If the first arg is __NEW__,
        this script should first create a new conda environment and then use it.
        """
    )

    def _expand_user_vars(self, string):
        """
        Expand user related variables in a given string
        Currently expands:
          {USERNAME} -> Name of the user
          {USERID} -> UserID
        """
        return string.format(
            USERNAME=self.user.name,
            USERID=self.user.id
        )

    def make_profile(
        self,
        conda_env_prefix,
        name=None,
        description=None,
        settings={}
    ):
        """
        Creates a ProfileSpawner profile tuple for a conda conda environemnt
        """

        if name is None:
            name = os.path.basename(conda_env_prefix)

        if description is None:
            description = name

        profile_settings = {
            'default_url': '/lab',
            'environment': self.environment,
            'debug': self.debug,
            'cmd':  [self.jupyterhub_singleuser_conda_env_script, conda_env_prefix]
        }

        profile_settings.update(settings)

        return (
            description, name, self.spawner_class,
            profile_settings
        )

    def make_conda_env_creating_profile(self):
        """
        Return a profile that will create a new stacked user conda env to use.
        """
        return self.make_profile(
            # __NEW__ is used by jupyterhub_singleuser_conda_env_script to indicate
            # that it should create a new stacked conda user env.
            conda_env_prefix='__NEW__',
            name='new_conda_env',
            description='Create and use new stacked conda environment...'
        )

    def _conda_cmd(self):
        return [self._expand_user_vars(a) for a in self.conda_cmd]

    def list_conda_envs(self):
        """
        Lists paths of existent conda envs.
        If you want to list only ones for a user, set conda_cmd to
        a command that will sudo as that user.
        """
        conda_info_cmd = self._conda_cmd() + ['info', '--json']
        conda_info = json.loads(subprocess.check_output(conda_info_cmd))
        return conda_info['envs']

    def _profile_sort_key(self, profile):
        """
        Sort key function for profiles.  We want
        profiles that contain user.name to come first, in descending order.
        Other profiles should be after.
        """
        profile_name = profile[1]
        if self.user.name in profile_name:
            return '1_{0}'.format(profile_name)
        else:
            return '0_{0}'.format(profile_name)

    def make_conda_env_profiles(self):
        """
        Returns a list of ProfileSpawner profiles for conda environments.
        """
        conda_profiles = []
        for conda_env_prefix in self.list_conda_envs():
            conda_env_name = os.path.basename(conda_env_prefix)
            conda_env_description = 'conda: {} (local)'.format(conda_env_name)

            if conda_env_prefix == self.conda_base_env_prefix:
                conda_env_description += ' (read only)'
                # Skip the base conda env if configured to do so.
                if not self.include_conda_base_env_profile:
                    continue

            profile = self.make_profile(
                conda_env_prefix=conda_env_prefix,
                name=conda_env_name,
                description=conda_env_description,
                # TODO: YarnSpawner?
            )
            conda_profiles.append(profile)

        conda_profiles.sort(reverse=True, key=self._profile_sort_key)
        return conda_profiles + [self.make_conda_env_creating_profile()]

    @property
    def profiles(self):
        return self.make_conda_env_profiles()
