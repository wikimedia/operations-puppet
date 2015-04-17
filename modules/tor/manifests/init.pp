# sets up a Tor relay
class tor (
    $tor_address,
    $tor_nickname,
    $tor_contact,
    $tor_controlport = '9051',
    $tor_orport = '443', # use 9001 if in use
    $tor_dirport = '80', # use 9030 if in use
    $tor_exit_policy = 'reject *:*',
    ) {

    # tor itself
    package { 'tor':
        ensure => 'present',
    }

    # status monitor for tor
    # https://www.atagar.com/arm/
    package { 'tor-arm':
        ensure => 'present',
    }

    # main config file
    file { '/etc/tor/torrc':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tor/torrc.erb'),
        notify  => Service['tor'],
        require => Package['tor'],
    }

    service { 'tor':
        ensure  => 'running',
        require => Package['tor'],
    }

    # actual Tor port where clients connect, public
    ferm::service { 'tor_orport':
        desc  => 'port for the actual Tor client connections',
        proto => 'tcp',
        port  => $tor_orport,
    }

    # for serving directory updates, public
    ferm::service { 'tor_dirport':
        desc  => 'port advertising the directory service',
        proto => 'tcp',
        port  => $tor_dirport,
    }

    motd::script { 'tor_arm':
        ensure  => present,
        content => "#!/bin/sh\necho '\nThis is a Tor relay. arm is a monitoring tool for it.\nusage: sudo -u debian-tor arm\nalso see: tail -f /var/log/tor/tor.log\n'",
    }

}
