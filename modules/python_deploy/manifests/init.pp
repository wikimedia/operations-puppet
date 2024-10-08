# SPDX-License-Identifier: Apache-2.0
# @summary Base class for deploying Python code
class python_deploy {
    ensure_packages(['virtualenv', 'make'])
    file { '/usr/local/bin/python-deploy-venv':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/python_deploy/python_deploy_venv.sh',
    }
}
