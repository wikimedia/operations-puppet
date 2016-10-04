# Class: role::toollabs::node::web::lighttpd
#
# This configures the compute node as a lighttpd web server
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class role::toollabs::node::web::lighttpd inherits role::toollabs::node::web {

    package { 'php5-cgi':
        ensure => latest,
    }

    package { [
        'lighttpd',
        'lighttpd-mod-magnet',        #T70614
        ]:
        ensure  => latest,
        require => File['/var/run/lighttpd'],
    }

    class { 'toollabs::queues': queues => [ 'webgrid-lighttpd' ] }

    file { '/var/run/lighttpd':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '1777',
    }
}
