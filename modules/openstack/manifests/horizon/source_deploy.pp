class openstack::horizon::source_deploy(
    $version,
    $nova_controller,
    $wmflabsdotorg_admin,
    $wmflabsdotorg_pass,
    $dhcp_domain,
    $ldap_user_pass,
    $venv_dir      = '/srv/deployment/horizon/venv',
    $webserver_hostname = 'newhorizon.wikimedia.org'
) {

    class { '::memcached':
        ip  => '127.0.0.1',
    }

    require_package(
        'python-wheel',
        'python-virtualenv',
        'virtualenv',
    )

    file { '/etc/openstack-dashboard':
        ensure => 'directory',
        owner  => 'root',
    }

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${version}/horizon/local_settings.py.erb"),
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        notify  => [Service['apache2'], Exec['djangorefresh']],
    }

    # In the perfect future, Horizon policies will be the same
    #  files that the respective services use.  In the meantime, though
    #  it's useful to be able to disable not-yet-supported horizon features.
    file { '/etc/openstack-dashboard/nova_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/nova_policy.json",
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0440',
        notify => Service['apache2'],
    }
    file { '/etc/openstack-dashboard/glance_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/glance_policy.json",
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0440',
        notify => Service['apache2'],
    }

    # We need a horizon-specific keystone policy because horizon does weird/special
    #  things for admin_required policies which I don't totally understand.  In particular,
    #  some permissive policies here (e.g. "") cause Horizon to panic, not ask Keystone for permission,
    #  and log out the user.
    file { '/etc/openstack-dashboard/keystone_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/keystone_policy.json",
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0440',
        notify => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/designate_policy.json':
        source => "puppet:///modules/openstack/${version}/designate/policy.json",
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0440',
        notify => Service['apache2'],
    }

    # This is a trivial policy file that forbids everything.  We'll use it
    #  for services that we don't support to prevent Horizon from
    #  displaying spurious panels.
    file { '/etc/openstack-dashboard/disabled_policy.json':
        source => "puppet:///modules/openstack/${version}/horizon/disabled_policy.json",
        owner  => 'horizon',
        group  => 'horizon',
        mode   => '0440',
        notify => Service['apache2'],
    }

    scap::target { 'horizon/deploy':
        deploy_user  => 'deploy-service',
    }

    # Collect and compress static web content
    exec { 'djangorefresh':
        command     => "virtualenv ${venv_dir}; python manage.py collectstatic --noinput && python manage.py compress",
        path        => '/usr/bin',
        cwd         => "${venv_dir}/usr/share/openstack-dashboard",
        require     => File['/etc/openstack-dashboard/local_settings.py'],
        notify      => Service['apache2'],
        refreshonly => true,
    }

    httpd::site { $webserver_hostname:
        content => template("openstack/${version}/horizon/${webserver_hostname}.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }
}
