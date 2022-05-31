# SPDX-License-Identifier: Apache-2.0
# == Class python_deploy::venv
#
# Deploy the bits needed to be able to deploy Python code in a simple manner, basically
# mimicking what scap does for the repositories of Python3 software that has frozen
# wheels and needs to be deployed in a virtualenv.
# This class was born as a workaround to not be blocked by the migration of Scap to
# Python 3 and might or might be not used after that.
#
# This class and scap::target are mutually exclusive, including both will results in
# compilation errors.
#
class python_deploy::venv (
    String $project_name,
    String $deploy_user,
) {
    systemd::sysuser { $deploy_user: }

    file { "/srv/deployment/${project_name}":
        ensure => directory,
        owner  => $deploy_user,
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/python-deploy-venv':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/python_deploy/python_deploy_venv.sh',
    }
}
