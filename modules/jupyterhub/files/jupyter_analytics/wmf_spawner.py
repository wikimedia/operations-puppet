#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.
"""
A SystemdSpawner that lets users choose one of their conda environments, or
create a new one, on the spawn page.

The single-user server always runs from the jupyter-analytics environment. The
user conda environments are kernels. The environment that the user chooses is
the default kernel for new notebooks, and terminals activate it.
"""
import asyncio
import html
import json
import os

from jupyterhub.spawner import SpawnException
from systemdspawner import SystemdSpawner
from traitlets import List, Unicode, default

# singleuser_script clones a new conda environment when it gets this value.
NEW_ENV = '__NEW__'


class CondaEnvSpawner(SystemdSpawner):

    conda_cmd = List(
        Unicode(),
        default_value=['conda'],
        help="""The command that runs conda as the user, to list the conda
        environments of the user. {USERNAME} and {USERID} are expanded.""",
    ).tag(config=True)

    hidden_env_prefixes = List(
        Unicode(),
        default_value=[],
        help='Do not offer the conda environments at these prefixes.',
    ).tag(config=True)

    singleuser_script = Unicode(
        default_value='/etc/jupyterhub/jupyterhub-singleuser.sh',
        help="""The script that starts jupyterhub-singleuser. Its first argument
        is the prefix of the chosen conda environment, or __NEW__.""",
    ).tag(config=True)

    async def list_conda_envs(self):
        """Return the prefixes of the conda environments of the user, in the order of the form."""
        cmd = [
            arg.format(USERNAME=self.user.name, USERID=self.user.id)
            for arg in self.conda_cmd
        ]
        proc = await asyncio.create_subprocess_exec(
            *cmd, 'info', '--json',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await proc.communicate()
        if proc.returncode != 0:
            raise RuntimeError(
                f'Cannot list the conda environments of {self.user.name}: {stderr.decode()}'
            )
        envs = [
            env for env in json.loads(stdout)['envs']
            if env not in self.hidden_env_prefixes
        ]

        # Put the environments with the user name first, newest first. The clone
        # script names environments <date>_<user name>.
        def sort_key(env):
            name = os.path.basename(env)
            return ('1_' if self.user.name in name else '0_') + name

        return sorted(envs, key=sort_key, reverse=True)

    @default('options_form')
    def _default_options_form(self):
        return self._render_options_form

    async def _render_options_form(self, spawner):
        envs = await self.list_conda_envs()
        choices = [(env, os.path.basename(env)) for env in envs]
        choices.append((NEW_ENV, 'Create and use new cloned conda environment...'))
        options = '\n'.join(
            f'<option value="{html.escape(value)}">{html.escape(label)}</option>'
            for value, label in choices
        )
        return f"""
<label for="conda_env" class="form-label">Conda environment</label>
<select class="form-select" id="conda_env" name="conda_env">
{options}
</select>
<p class="form-text">
This environment is the default kernel for new notebooks, and terminals activate it.
You can use your other conda environments from the kernel menu of each notebook.
</p>
"""

    def options_from_form(self, formdata):
        return {'conda_env': formdata.get('conda_env', [''])[0]}

    async def start(self):
        envs = await self.list_conda_envs()
        env = self.user_options.get('conda_env')
        if not env:
            # A spawn from the API has no form data. Use the first choice of the form.
            env = envs[0] if envs else NEW_ENV
        if env != NEW_ENV and env not in envs:
            raise SpawnException(
                f'{env} is not one of the conda environments of {self.user.name}.',
                reason='conda_env',
            )
        # SystemdSpawner expands {USERNAME} in each part of cmd, so braces break the spawn.
        if '{' in env or '}' in env:
            raise SpawnException(
                f'Cannot start a server for {env}, because its path contains braces.',
                reason='conda_env',
            )
        self.cmd = [self.singleuser_script, env]
        return await super().start()
