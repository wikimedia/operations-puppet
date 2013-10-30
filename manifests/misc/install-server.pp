# misc/install-server.pp

class misc::install-server {
    system::role { 'misc::install-server': description => 'Install server' }

    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
              'srv-wikimedia',
            ]
    include backup::host
    backup::set { $sets : }

    class web-server {
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

        # Monitoring
        monitor_service { 'http':
            description   => 'HTTP',
            check_command => 'check_http',
        }
    }

    class tftp-server {
        system::role { 'misc::tftp-server': description => 'TFTP server' }

        # TODO: replace this by iptables.pp definitions
        $iptables_command = '
            /sbin/iptables -F tftp;
            /sbin/iptables -A tftp -s 10.0.0.0/8 -j ACCEPT;
            /sbin/iptables -A tftp -s 208.80.152.0/22 -j ACCEPT;
            /sbin/iptables -A tftp -s 91.198.174.0/24 -j ACCEPT;
            /sbin/iptables -A tftp -s 198.35.26.0/22 -j ACCEPT;
            /sbin/iptables -A tftp -j DROP;
            /sbin/iptables -I INPUT -p udp --dport tftp -j tftp
            '

        exec { 'tftp-firewall-rules':
            command => $iptables_command,
            onlyif  => '/sbin/iptables -N tftp',
            path    => '/sbin',
            timeout => 5,
            user    => 'root',
        }

        file {
            '/srv/tftpboot':
                # config files in the puppet repository,
                # larger files like binary images in volatile
                source          => [ 'puppet:///files/tftpboot', 'puppet:///volatile/tftpboot' ],
                sourceselect    => all,
                mode            => '0444',
                owner           => 'root',
                group           => 'root',
                recurse         => remote;
            '/srv/tftpboot/restricted/':
                ensure  => directory,
                mode    => '0755',
                owner   => 'root',
                group   => 'root';
            '/tftpboot':
                ensure => link,
                target => '/srv/tftpboot';
        }

        package { 'openbsd-inetd':
            ensure => latest,
        }

        # Started by inetd
        package { 'atftpd':
            ensure  => latest,
            require => [ Package[openbsd-inetd], Exec[tftp-firewall-rules] ],
        }
    }

    class caching-proxy {
        system::role { 'misc::caching-proxy':
            description => 'Caching proxy server'
        }

        file { '/etc/squid/squid.conf':
            ensure  => present,
            require => Package[squid],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/etc/squid/squid.conf',
            source  => 'puppet:///files/squid/apt-proxy.conf',
        }

        file { '/etc/logrotate.d/squid':
            ensure  => present,
            require => Package[squid],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/etc/logrotate.d/squid',
            source  => 'puppet:///files/logrotate/squid',
        }

        # pin package to the default, Ubuntu version, instead of our own
        apt::pin { [ 'squid', 'squid-common', 'squid-langpack' ]:
            pin      => 'release o=Ubuntu',
            priority => '1001',
            before   => Package['squid'],
        }

        package { 'squid':
            ensure => latest,
        }

        service { 'squid':
            ensure      => running,
            require     => [ File['/etc/squid/squid.conf'], Package[squid] ],
            subscribe   => File['/etc/squid/squid.conf'],
        }

        # Monitoring
        monitor_service { 'squid':
            description   => 'Squid',
            check_command => 'check_tcp!8080',
        }
    }

    class ubuntu-mirror {
        system::role { 'misc::ubuntu-mirror':
            description => 'Public Ubuntu mirror'
        }

        # Top level directory must exist
        file { '/srv/ubuntu/':
            ensure  => directory,
            require => Systemuser[mirror],
            mode    => '0755',
            owner   => 'mirror',
            group   => 'mirror',
            path    => '/srv/ubuntu/',
        }

        # Update script
        file { 'update-ubuntu-mirror':
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
            path    => '/usr/local/sbin/update-ubuntu-mirror',
            source  => 'puppet:///files/misc/update-ubuntu-mirror',
        }

        # System user and group for mirroring
        generic::systemuser { 'mirror': name => 'mirror', home => '/var/lib/mirror' }

        # Mirror update cron entry
        cron { 'update-ubuntu-mirror':
            ensure  => present,
            require => [ Systemuser[mirror], File['update-ubuntu-mirror'] ],
            command => '/usr/local/sbin/update-ubuntu-mirror 1>/dev/null 2>/var/lib/mirror/mirror.err.log',
            user    => mirror,
            hour    => '*/6',
            minute  => 43,
        }
    }

    class apt-repository {
        system::role { 'misc::apt-repository': description => 'APT repository' }

        package { [ 'dpkg-dev', 'gnupg', 'reprepro', 'dctrl-tools' ]:
            ensure => latest,
        }

        # TODO: add something that sets up /etc/environment for reprepro

        file {
            '/srv/wikimedia/':
                ensure  => directory,
                mode    => '0755',
                owner   => 'root',
                group   => 'root';
            '/usr/local/sbin/update-repository':
                mode    => '0555',
                owner   => 'root',
                group   => 'root',
                path    => '/usr/local/sbin/update-repository',
                content => '#! /bin/bash
echo "update-repository is no longer used; the Wikimedia APT repository is now managed using reprepro. See [[wikitech:reprepro]] for more information."
'
        }

        # Reprepro configuration
        file {
            '/srv/wikimedia/conf':
                ensure  => directory,
                mode    => '0755',
                owner   => 'root',
                group   => 'root';
            '/srv/wikimedia/conf/log':
                mode    => '0755',
                owner   => 'root',
                group   => 'root',
                source  => 'puppet:///files/misc/reprepro/log';
            '/srv/wikimedia/conf/distributions':
                mode    => '0444',
                source  => 'puppet:///files/misc/reprepro/distributions';
            '/srv/wikimedia/conf/updates':
                mode    => '0444',
                source  => 'puppet:///files/misc/reprepro/updates';
            '/srv/wikimedia/conf/incoming':
                mode    => '0444',
                source  => 'puppet:///files/misc/reprepro/incoming';
        }

        alert('The Wikimedia Archive Signing GPG keys need to be installed manually on this host.')
    }

    class preseed-server {
        file { '/srv/autoinstall':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            path    => '/srv/autoinstall/',
            source  => 'puppet:///files/autoinstall',
            recurse => true,
            links   => manage
        }
    }

    class dhcp-server {
        file { '/etc/dhcp3/' :
            ensure      => directory,
            require     => Package[dhcp3-server],
            recurse     => true,
            owner       => 'root',
            group       => 'root',
            mode        => '0444',
            source      => 'puppet:///files/dhcpd',
        }

        package { 'dhcp3-server':
            ensure => latest;
        }

        service { 'dhcp3-server':
            ensure    => running,
            require   => [Package[dhcp3-server],
                          File['/etc/dhcp3' ]
                          ],
            subscribe => File['/etc/dhcp3' ],
        }
    }

    include misc::install-server::ubuntu-mirror,
        misc::install-server::apt-repository,
        misc::install-server::preseed-server,
        misc::install-server::tftp-server,
        misc::install-server::caching-proxy,
        misc::install-server::web-server,
        misc::install-server::dhcp-server
}
