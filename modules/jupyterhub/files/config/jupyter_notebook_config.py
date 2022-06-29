# SPDX-License-Identifier: Apache-2.0
# NOTE: This file is managed by Puppet.

# Explicitly configure the shell that will be used by the Jupyter Notebook Terminal app,
# AKA terminando.  Without this, Jupyter will launch the terminals as a login shell (-l).
# While this is often desired, in our case with stacked conda environments, the shell should
# already be set up properly, and we do not want e.g. /etc/profile sourced again.
# See https://github.com/jupyter/notebook/blob/master/notebook/terminal/__init__.py#L28-L34


c.NotebookApp.terminado_settings = {  # noqa: F821
    'shell_command': ['/bin/bash']
}
