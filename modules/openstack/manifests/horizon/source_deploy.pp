# Because we deploy Horizon from source, and because
# the OpenStack APIs are backwards-compatible, we typically
# deploy a newer version of Horizon than the other OpenStack services.
#
# That means we track two different version settings here:
#
#  $horizon_version: the actual version of Horizon that's running
#
#  $openstack_version: the version used for the other openstack
#   services on e.g. cloudcontrol1001.
#
# We need to know the value of $openstack_version so that we can
# pull the policy files that Horizon uses from the appropriate services
# and avoid having to duplicate them just for Horizon to consume.
#
# SPDX-License-Identifier: Apache-2.0
class openstack::horizon::source_deploy(
    String        $horizon_version,
    String        $venv_dir           = '/srv/deployment/horizon/venv',
    Stdlib::Fqdn  $webserver_hostname = 'horizon.wikimedia.org',
) {
    ensure_packages([
        'python-wheel',
        'python-virtualenv',
        'virtualenv',
        'gettext',
    ])

    # A user and group to run this as
    group { 'horizon':
        ensure => present,
        name   => 'horizon',
        system => true,
    }

    user { 'horizon':
        gid        => 'horizon',
        system     => true,
        managehome => true,
    }

    scap::target { 'horizon/deploy':
        deploy_user  => 'deploy-service',
        service_name => 'apache2',
    }

    # allow deploy-service to restart apache as root.
    # Also, it needs to sudo as horizon to gather and compress
    #  static content.
    sudo::user { 'deploy-service':
        privileges => [
            'ALL = (root) NOPASSWD: /usr/sbin/service apache2 start',
            'ALL = (root) NOPASSWD: /usr/sbin/apache2ctl graceful-stop',
            'ALL = (horizon) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /bin/chown -R horizon /srv/deployment/horizon/venv/*',
            'ALL = (root) NOPASSWD: /bin/chown -R deploy-service /srv/deployment/horizon/venv/*',
        ],
    }

    httpd::site { $webserver_hostname:
        content => template("openstack/${horizon_version}/horizon/${webserver_hostname}.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }

    # Prepare this directory for scap to drop some files into
    file { '/etc/openstack-dashboard/default_policies':
        ensure  => 'directory',
        owner   => 'deploy-service',
        require => File['/etc/openstack-dashboard'],
    }

    file { '/var/lib/openstack-dashboard':
        ensure => 'directory',
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0755',
    }

    file { '/var/lib/openstack-dashboard/static':
        ensure  => 'directory',
        owner   => 'horizon',
        mode    => '0755',
        require => File['/var/lib/openstack-dashboard'],
    }

    file { '/var/lib/openstack-dashboard/static/maintenance.html':
        source  => 'puppet:///modules/openstack/horizon/maintenance.html',
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0755',
        require => File['/var/lib/openstack-dashboard/static'],
    }

    file { '/home/horizon/.ssh/':
        ensure  => absent,
        recurse => true,
        force   => true,
        purge   => true,
    }
}
