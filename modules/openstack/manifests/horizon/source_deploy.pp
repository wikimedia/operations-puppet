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
class openstack::horizon::source_deploy(
    String        $horizon_version,
    String        $openstack_version,
    Stdlib::Fqdn  $keystone_api_fqdn,
    String        $wmflabsdotorg_admin,
    String        $wmflabsdotorg_pass,
    Stdlib::Fqdn  $dhcp_domain,
    String        $instance_network_id,
    Stdlib::Host  $ldap_rw_host,
    String        $ldap_user_pass,
    Array[String] $all_regions,
    String        $puppet_git_repo_name,
    String        $puppet_git_repo_user,
    String        $secret_key,
    Hash          $proxy_zone_dict,
    Hash          $proxy_zone_passwords,
    String        $venv_dir           = '/srv/deployment/horizon/venv',
    Stdlib::Fqdn  $webserver_hostname = 'horizon.wikimedia.org',
    Boolean       $maintenance_mode   = false,
) {
    ensure_packages([
        'python-wheel',
        'python-virtualenv',
        'virtualenv',
        'gettext',
    ])

    $puppet_git_repo_key_path = '/home/horizon/.ssh/instance-puppet-user.priv'

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${horizon_version}/horizon/local_settings.py.erb"),
        mode    => '0444',
        owner   => 'root',
        notify  => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/nova_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/nova/common/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/keystone_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/keystone/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/glance_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/glance/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/designate_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/designate/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/neutron_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/neutron/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/cinder_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/cinder/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/trove_policy.yaml':
        source => "puppet:///modules/openstack/${openstack_version}/trove/policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

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

    # This is a trivial policy file that forbids everything.  We'll use it
    #  for services that we don't support to prevent Horizon from
    #  displaying spurious panels.
    file { '/etc/openstack-dashboard/disabled_policy.yaml':
        source => "puppet:///modules/openstack/${horizon_version}/horizon/disabled_policy.yaml",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
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

    # We need to do some work that would otherwise by handled by the horizon
    #  debian package
    file { '/etc/openstack-dashboard':
        ensure => 'directory',
        owner  => 'root',
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

    # Get ready to host a local git repo of instance puppet config
    file { '/home/horizon/.ssh/':
        ensure => 'directory',
        owner  => 'horizon',
        mode   => '0600',
    }

    file { $puppet_git_repo_key_path:
        ensure    => file,
        owner     => 'horizon',
        group     => 'horizon',
        mode      => '0600',
        content   => secret('ssh/instance-puppet-user/instance-puppet-user_privkey.pem'),
        show_diff => false,
    }

}
