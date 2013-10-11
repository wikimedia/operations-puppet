# misc/install-server.pp

class install-server::tftp-server {

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
