#

class install-server::web-server {
    package { 'lighttpd':
        ensure => latest,
    }

    file {
        'lighttpd.conf':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/etc/lighttpd/lighttpd.conf',
            source  => 'puppet:///files/lighttpd/install-server.conf';
        'logrotate-lighttpd-install-server':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/etc/logrotate.d/lighttpd',
            source  => 'puppet:///files/logrotate/lighttpd-install-server';
    }

    service { 'lighttpd':
        ensure      => running,
        require     => [ File['lighttpd.conf'], Package[lighttpd] ],
        subscribe   => File['lighttpd.conf'],
    }

}
