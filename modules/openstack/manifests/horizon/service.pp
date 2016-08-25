# The OpenStack Dashboard Project
# http://docs.openstack.org/developer/horizon/
class openstack::horizon::service(
    $openstack_version  = $::openstack::version,
    $webserver_hostname = 'horizon.wikimedia.org',
    $novaconfig,
    $designateconfig)
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

    include ::nginx
    include ::memcached

    # Blank out these files so that the (broken) dashboard
    #  package doesn't fret.
    file { ['/etc/apache2/conf-available/openstack-dashboard.conf',
            '/etc/apache2/conf-enabled/openstack-dashboard.conf']:
        ensure  => file,
        content => '# This empty file is here to keep the openstack-dashboard package happy.',
        require => Package['openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${openstack_version}/horizon/local_settings.py.erb"),
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

    $app_dir = '${app_dir}'
    file { "${app_dir}/openstack_dashboard/static/dashboard/img/logo.png":
        source  => 'puppet:///modules/openstack/horizon/216px-Wikimedia_labs_dashboard_logo.png',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0444',
    }
    file { "${app_dir}/openstack_dashboard/static/dashboard/img/logo-splash.png":
        source  => 'puppet:///modules/openstack/horizon/180px-Wikimedia_labs_dashboard_splash.png',
        owner   => 'horizon',
        group   => 'horizon',
        require => Package['openstack-dashboard'],
        mode    => '0444',
    }
    file { "${app_dir}/openstack_dashboard/static/dashboard/img/favicon.ico":
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
    file { "${app_dir}/openstack_dashboard/local":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { "${app_dir}/openstack_dashboard/local/enabled":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { "${app_dir}/openstack_dashboard/local/enabled/_70_dns_add_group.py":
        source  => "puppet:///modules/openstack/${openstack_version}/designate/dashboard/_70_dns_add_group.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
    file { "${app_dir}/openstack_dashboard/local/enabled/_71_dns_project.py":
        source  => "puppet:///modules/openstack/${openstack_version}/designate/dashboard/_71_dns_project.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }

    # Proxy panel
    file { '/usr/lib/python2.7/dist-packages/wikimediaproxydashboard':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/proxy",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        recurse => true
    }
    file { "${app_dir}/openstack_dashboard/local/enabled/_1922_project_proxy_panel.py":
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/proxy_enable.py",
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

    # Arbitrary handy script that needs to be on the horizon host because it only works with Liberty
    file { '/root/makedomain':
        source => "puppet:///modules/openstack/${openstack_version}/virtscripts/makedomain",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    $uwsgi_port = 8080
    service::uwsgi { 'horizon':
        port            => $uwsgi_port,
        config          => {
            chdir     => $app_dir,
            wsgi-file => 'openstack_dashboard/wsgi/django.wsgi',
            uid       => 'horizon',
            gid       => 'horizon',
            vacuum    => true,
        },
        healthcheck_url => '/',
        firejail        => false,
        # We don't use scap3 to deploy, the files are already here
        deployment      => 'puppet',
        require         => File['/etc/openstack-dashboard/local_settings.py'],
    }
    nginx::site { 'horizon':
        content => template('openstack/horizon/nginx.conf.erb'),
    }
}
