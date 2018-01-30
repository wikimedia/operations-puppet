# The OpenStack Das2hboard Project
# http://docs.openstack.org/developer/horizon/
class openstack::horizon::service(
    $version,
    $nova_controller,
    $wmflabsdotorg_admin,
    $wmflabsdotorg_pass,
    $dhcp_domain,
    $ldap_user_pass,
    $webserver_hostname = 'horizon.wikimedia.org'
) {

    include ::memcached

    package { 'openstack-dashboard':
        ensure  => 'present',
    }

    require_package([
        'python-keystoneclient',
        'python-keystone',
        'python-mysqldb',
        ]
    )

    package { [ 'python-openstack-auth',
                'python-designate-dashboard' ]:
        ensure  => 'present',
    }

    # Blank out these files so that the (broken) dashboard
    #  package doesn't fret.
    file { ['/etc/apache2/conf-available/openstack-dashboard.conf',
            '/etc/apache2/conf-enabled/openstack-dashboard.conf']:
        ensure  => file,
        content => '# This empty file is here to keep the openstack-dashboard package happy.',
        require => Package['openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${version}/horizon/local_settings.py.erb"),
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => [Service['apache2'], Exec['djangorefresh']],
    }

    # In the perfect future, Horizon policies will be the same
    #  files that the respective services use.  In the meantime, though
    #  it's useful to be able to disable not-yet-supported horizon features.
    file { '/etc/openstack-dashboard/nova_policy.json':
        source  => "puppet:///modules/openstack/${version}/horizon/nova_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => Service['apache2'],
    }
    file { '/etc/openstack-dashboard/glance_policy.json':
        source  => "puppet:///modules/openstack/${version}/horizon/glance_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => Service['apache2'],
    }

    # We need a horizon-specific keystone policy because horizon does weird/special
    #  things for admin_required policies which I don't totally understand.  In particular,
    #  some permissive policies here (e.g. "") cause Horizon to panic, not ask Keystone for permission,
    #  and log out the user.
    file { '/etc/openstack-dashboard/keystone_policy.json':
        source  => "puppet:///modules/openstack/${version}/horizon/keystone_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => Service['apache2'],
    }

    file { '/etc/openstack-dashboard/designate_policy.json':
        source  => "puppet:///modules/openstack/${version}/designate/policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => Service['apache2'],
    }

    # This is a trivial policy file that forbids everything.  We'll use it
    #  for services that we don't support to prevent Horizon from
    #  displaying spurious panels.
    file { '/etc/openstack-dashboard/disabled_policy.json':
        source  => "puppet:///modules/openstack/${version}/horizon/disabled_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0440',
        require => Package['openstack-dashboard'],
        notify  => Service['apache2'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png':
        source  => 'puppet:///modules/openstack/horizon/125px-Cloud_VPS_dashboard_logo.png',
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0444',
        require => Package['openstack-dashboard'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png':
        source  => 'puppet:///modules/openstack/horizon/180px-Cloud_VPS_dashboard_splash.png',
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0444',
        require => Package['openstack-dashboard'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/favicon.ico':
        source  => 'puppet:///modules/openstack/horizon/Cloud_VPS.ico',
        owner   => 'horizon',
        group   => 'horizon',
        mode    => '0444',
        require => Package['openstack-dashboard'],
    }

    # Homemade totp plugin for keystoneclient
    file { '/usr/lib/python2.7/dist-packages/keystoneclient/auth/identity/v3/wmtotp.py':
        source => "puppet:///modules/openstack/${version}/keystoneclient/wmtotp.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/lib/python2.7/dist-packages/keystoneclient/auth/identity/v3/__init__.py':
        source => "puppet:///modules/openstack/${version}/keystoneclient/__init__.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # Homemade totp plugin for openstack_auth
    file { '/usr/lib/python2.7/dist-packages/openstack_auth/plugin/wmtotp.py':
        source  => "puppet:///modules/openstack/${version}/horizon/openstack_auth/wmtotp.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-openstack-auth'],
    }

    # Replace the standard horizon login form to support 2fa
    file { '/usr/lib/python2.7/dist-packages/openstack_auth/forms.py':
        source  => "puppet:///modules/openstack/${version}/horizon/openstack_auth/forms.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-openstack-auth'],
    }

    # Replace the standard login backend.py to fix
    #  https://bugs.launchpad.net/django-openstack-auth/+bug/1562452
    # and also to implement the 'rememberme' checkbox
    file { '/usr/lib/python2.7/dist-packages/openstack_auth/backend.py':
        source  => "puppet:///modules/openstack/${version}/horizon/openstack_auth/backend.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-openstack-auth'],
    }

    # Install the designate dashboard
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_70_dns_add_group.py':
        source  => "puppet:///modules/openstack/${version}/designate/dashboard/_70_dns_add_group.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_71_dns_project.py':
        source  => "puppet:///modules/openstack/${version}/designate/dashboard/_71_dns_project.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    # Proxy panel
    file { '/usr/lib/python2.7/dist-packages/wikimediaproxydashboard':
        source  => "puppet:///modules/openstack/${version}/horizon/proxy",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1922_project_proxy_panel.py':
        source  => "puppet:///modules/openstack/${version}/horizon/proxy_enable.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
    }

    # sudo dashboard
    file { '/usr/lib/python2.7/dist-packages/wikimediasudodashboard':
        source  => "puppet:///modules/openstack/${version}/horizon/sudo",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1926_project_sudo_panel.py':
        source  => "puppet:///modules/openstack/${version}/horizon/sudo_enable.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_72_sudoers_add_group.py':
        source  => "puppet:///modules/openstack/${version}/horizon/sudo_group_add.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
    }

    if $version != 'liberty' {
        # Override some .js files to provide a simplified user experience.  Alas
        #  we can't do this via the overrides.py monkeypatch below

        file { '/usr/share/openstack-dashboard/openstack_dashboard/dashboards/project/static/dashboard/project/workflow/launch-instance/launch-instance-workflow.service.js':
            source  => "puppet:///modules/openstack/${version}/horizon/jsoverrides/launch-instance-workflow.service.js",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package['openstack-dashboard'],
            notify  => Exec['djangorefresh'],
        }
    }

    # Monkeypatches for Horizon customization
    file { '/usr/lib/python2.7/dist-packages/horizon/overrides.py':
        source  => "puppet:///modules/openstack/${version}/horizon/overrides.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-openstack-auth'],
    }

    # Arbitrary handy script that needs to be on the horizon host because it only works with Liberty
    file { '/root/makedomain':
        source => "puppet:///modules/openstack/${version}/admin_scripts/makedomain",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    httpd::site { $webserver_hostname:
        content => template("openstack/${version}/horizon/${webserver_hostname}.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }

    # Collect and compress static web content
    exec { 'djangorefresh':
        command     => 'python manage.py collectstatic --noinput && python manage.py compress',
        path        => '/usr/bin',
        cwd         => '/usr/share/openstack-dashboard',
        require     => File['/etc/openstack-dashboard/local_settings.py'],
        notify      => Service['apache2'],
        refreshonly => true,
    }
}
