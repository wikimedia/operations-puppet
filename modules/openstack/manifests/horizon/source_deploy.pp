class openstack::horizon::source_deploy(
    $version,
    $keystone_host,
    $wmflabsdotorg_admin,
    $wmflabsdotorg_pass,
    $dhcp_domain,
    $instance_network_id,
    $ldap_user_pass,
    $all_regions,
    $puppet_git_repo_name,
    $puppet_git_repo_user,
    $venv_dir      = '/srv/deployment/horizon/venv',
    $webserver_hostname = 'horizon.wikimedia.org',
    $maintenance_mode = false,
) {
    require_package(
        'python-wheel',
        'python-virtualenv',
        'virtualenv',
        'gettext',
    )

    $puppet_git_repo_key_path = '/home/horizon/.ssh/instance-puppet-user.priv'
    $puppet_git_repo_base_path = '/var/lib/git/cloud/'

    file { $puppet_git_repo_key_path:
        ensure    => file,
        owner     => 'horizon',
        group     => 'horizon',
        mode      => '0600',
        content   => secret('ssh/instance-puppet-user/instance-puppet-user_privkey.pem'),
        show_diff => false,
    }

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${version}/horizon/local_settings.py.erb"),
        mode    => '0444',
        owner   => 'root',
        notify  => Service['apache2'],
    }

    # In the perfect future, Horizon policies will be the same
    #  files that the respective services use.  In the meantime, though
    #  it's useful to be able to disable not-yet-supported horizon features.
    file { '/etc/openstack-dashboard/nova_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/nova_policy.json",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }
    file { '/etc/openstack-dashboard/glance_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/glance_policy.json",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    # We need a horizon-specific keystone policy because horizon does weird/special
    #  things for admin_required policies which I don't totally understand.  In particular,
    #  some permissive policies here (e.g. "") cause Horizon to panic, not ask Keystone for permission,
    #  and log out the user.
    file { '/etc/openstack-dashboard/keystone_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/keystone_policy.json",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/designate_policy.json':
        source => "puppet:///modules/openstack/${version}/designate/policy.json",
        owner  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/neutron_policy.json':
        source => "puppet:///modules/openstack/${version}/neutron/policy.json",
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
    file { '/etc/openstack-dashboard/disabled_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/disabled_policy.json",
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
        content => template("openstack/${version}/horizon/${webserver_hostname}.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }

    # We need to do some work that would otherwise by handled by the horizon
    #  debian package
    file { '/etc/openstack-dashboard':
        ensure => 'directory',
        owner  => 'root',
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
    file { '/var/lib/git/cloud':
        ensure => 'directory',
        owner  => 'horizon',
        mode   => '0755',
    }
}
