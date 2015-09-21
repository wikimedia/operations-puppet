# == Class: apache::monitoring
#
# Configures Apache to serve a server status page via mod_status
# at /server-status (exposed only to requests originating on the
# server), and provisions metric-gathering modules for Diamond
# and Ganglia.
#
class apache::monitoring {
    include ::apache::mod::status
    include ::ganglia

    # The default mod_status configuration enables /server-status on all
    # vhosts for local requests, but it does not correctly distinguish
    # between requests which are truly local and requests that have been
    # proxied. So replace the default config with a more conservative one.
    apache::conf { 'server_status':
        source   => 'puppet:///modules/apache/status.conf',
        replaces => '/etc/apache2/mods-enabled/status.conf',
        require  =>  Apache::Mod_conf['status'],
    }

    # Use `links -dump http://127.0.0.1/server-status` to generate
    # an Apache status report.
    require_package('links')

    diamond::collector { 'Httpd':
        ensure   => absent,
        settings => {
            path => "${::site}.${cluster}.httpd",
            urls => 'http://127.0.0.1/server-status?auto'
        },
    }

    file { '/usr/lib/ganglia/python_modules/apache_status.py':
        source  => 'puppet:///modules/apache/apache_status.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/apache_status.pyconf':
        source  => 'puppet:///modules/apache/apache_status.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/lib/ganglia/python_modules/apache_status.py'],
        notify  => Service['ganglia-monitor'],
    }

    file { '/usr/local/bin/apache-status':
        source  => 'puppet:///modules/apache/apache-status',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
}
