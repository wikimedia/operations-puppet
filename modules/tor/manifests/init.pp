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
    $apt_uri,
    $apt_dist,
) {

    if os_version('debian >= stretch') {

        apt::repository { 'thirdparty-tor':
            uri        => $apt_uri,
            dist       => $apt_dist,
            components => 'thirdparty/tor',
        }

        package { 'tor':
            ensure  => 'present',
            require => [ Apt::Repository['thirdparty-tor'],Exec['apt-get update']],
        }

    } else {

        package { 'tor':
            ensure  => 'present',
        }
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
