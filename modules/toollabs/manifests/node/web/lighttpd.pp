# Class: toollabs::node::web::lighttpd
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
class toollabs::node::web::lighttpd inherits toollabs::node::web {

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

    file { '/usr/local/bin/tool-lighttpd':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/tool-lighttpd',
    }

    file { '/usr/local/bin/lighttpd-starter':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/lighttpd-starter',
    }

}

