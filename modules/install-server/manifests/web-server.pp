# Class: install-server::web-server
#
# This class installs and configures lighttpd to act as a repository for new
# installation enviroments
#
# Parameters:
#
# Actions:
#   Install and configure lighttpd
#
# Requires:
#
# Sample Usage:
#   include install-server::web-server

class install-server::web-server {
    package { 'lighttpd':
        ensure => latest,
    }

    file {
        '/etc/lighttpd/lighttpd.conf':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/lighttpd.conf';
        '/etc/logrotate.d/lighttpd':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/install-server/logrotate-lighttpd';
    }

    service { 'lighttpd':
        ensure      => running,
        require     => [ File['/etc/lighttpd/lighttpd.conf'], Package['lighttpd'] ],
        subscribe   => File['/etc/lighttpd/lighttpd.conf'],
    }
}
