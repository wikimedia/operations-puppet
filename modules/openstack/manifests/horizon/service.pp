# The OpenStack Dashboard Project
# http://docs.openstack.org/developer/horizon/
class openstack::horizon::service(
    $openstack_version  = $::openstack::version,
    $webserver_hostname = 'labsconsole.wikimedia.org',
    $novaconfig)
{
    # basic horizon packages and config
    include openstack::repo

    package { 'openstack-dashboard':
        ensure  => present,
        require => Class['openstack::repo',  '::apache::mod::wsgi'];
    }

    package { [ 'python-keystoneclient',
                'python-openstack-auth',
                'python-designate-dashboard' ]:
        ensure  => present,
    }

    include ::apache
    include ::apache::mod::ssl
    include ::apache::mod::wsgi
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    if !defined(Class['memcached']) {
        class { 'memcached':
            ip => '127.0.0.1',
        }
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
        content => template("openstack/${$openstack_version}/horizon/local_settings.py.erb"),
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }

    # In the perfect future, Horizon policies will be the same
    #  files that the respective services use.  In the meantime, though
    #  it's useful to be able to disable not-yet-supported horizon features.
    file { '/etc/openstack-dashboard/nova_policy.json':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/nova_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }
    file { '/etc/openstack-dashboard/glance_policy.json':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/glance_policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }

    # With luck, in the future all horizon policy files will be identical to the service policies
    #  like this one is.
    file { '/etc/openstack-dashboard/keystone_policy.json':
        source  => "puppet:///modules/openstack/${openstack_version}/keystone/policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }
    file { '/etc/openstack-dashboard/designate_policy.json':
        source  => "puppet:///modules/openstack/${openstack_version}/designate/policy.json",
        owner   => 'horizon',
        group   => 'horizon',
        notify  => Service['apache2'],
        require => Package['openstack-dashboard'],
        mode    => '0440',
    }

    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo.png':
        source  => 'puppet:///modules/openstack/horizon/216px-Wikimedia_labs_dashboard_logo.png',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0444',
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/logo-splash.png':
        source  => 'puppet:///modules/openstack/horizon/180px-Wikimedia_labs_dashboard_splash.png',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0444',
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/static/dashboard/img/favicon.ico':
        source  => 'puppet:///modules/openstack/horizon/Wikimedia_labs.ico',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0444',
    }

    # Homemade totp plugin for keystoneclient
    file { '/usr/lib/python2.7/dist-packages/keystoneclient/auth/identity/v3/wmtotp.py':
        source  => "puppet:///modules/openstack/${openstack_version}/keystoneclient/wmtotp.py",
        owner   => 'root',
        group   => 'root',
        require => Package['python-keystoneclient'],
        mode    => '0644',
    }
    file { '/usr/lib/python2.7/dist-packages/keystoneclient/auth/identity/v3/__init__.py':
        source  => "puppet:///modules/openstack/${openstack_version}/keystoneclient/__init__.py",
        owner   => 'root',
        group   => 'root',
        require => Package['python-keystoneclient'],
        mode    => '0644',
    }

    # Homemade totp plugin for openstack_auth
    file { '/usr/lib/python2.7/dist-packages/openstack_auth/plugin/wmtotp.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/wmtotp.py",
        owner   => 'root',
        group   => 'root',
        require => Package['python-openstack-auth'],
        mode    => '0644',
    }

    # Replace the standard horizon login form to support 2fa
    file { '/usr/lib/python2.7/dist-packages/openstack_auth/forms.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/forms.py",
        owner   => 'root',
        group   => 'root',
        require => Package['python-openstack-auth'],
        mode    => '0644',
    }

    # Install the designate dashboard
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local':
        ensure => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled':
        ensure => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_70_dns_add_group.py':
        source  => "puppet:///modules/openstack/${openstack_version}/designate/dashboard/_70_dns_add_group.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_71_dns_project.py':
        source  => "puppet:///modules/openstack/${openstack_version}/designate/dashboard/_71_dns_project.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    # Monkeypatches for Horizon customization
    file { '/usr/lib/python2.7/dist-packages/horizon/overrides.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/overrides.py",
        owner   => 'root',
        group   => 'root',
        require => Package['python-openstack-auth'],
        mode    => '0644',
    }

    apache::site { $webserver_hostname:
        content => template("openstack/${$openstack_version}/horizon/${webserver_hostname}.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }
    # Redirect for the old site name
    apache::site { 'horizon.wikimedia.org':
        content => template("openstack/${$openstack_version}/horizon/horizon.wikimedia.org.erb"),
        require => File['/etc/openstack-dashboard/local_settings.py'],
    }
}
