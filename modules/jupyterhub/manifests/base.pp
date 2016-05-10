# == Class: jupyterhub::base
# Base class for setting up JupyterHub - very WIP
#
class jupyterhub::base{
    ensure_packages([
                    'npm',
                    'nodejs-legacy',])

}
