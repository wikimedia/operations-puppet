# == Class: apache::monitoring
#
# Configures Apache to serve a server status page via mod_status
# at /server-status (exposed only to requests originating on the
# server), and provisions metric-gathering modules for Diamond.
#
class apache::monitoring {
    include ::apache::mod::status

    # Use `links -dump http://127.0.0.1/server-status` to generate
    # an Apache status report.
    require_package('links')

    file { '/usr/local/bin/apache-status':
        source => 'puppet:///modules/apache/apache-status',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
