# sets up a Tor relay
class tor(
    $address,
    $nickname,
    $contact,
    $controlport,
    $controlpassword,
    $orport,
    $dirport,
    $exit_policy,
) {

    package { 'tor':
        ensure => 'present',
    }

    # status monitor for tor - https://www.atagar.com/arm/
    package { 'tor-arm':
        ensure => 'present',
    }

    file { '/etc/tor/torrc':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tor/torrc.erb'),
        notify  => Service['tor'],
        require => Package['tor'],
    }

    exec { 'tor-systemd-reload':
        refreshonly => true,
        command     => '/bin/systemctl daemon-reload',
    }

    service { 'tor':
        ensure  => 'running',
        require => Package['tor'],
    }
}
