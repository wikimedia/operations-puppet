# sets up a Tor relay
class tor(
    Variant[Stdlib::Ip_address, Stdlib::Fqdn] $address,
    String $nickname,
    String $contact,
    Stdlib::Port $controlport,
    String $controlpassword,
    Stdlib::Port $orport,
    Stdlib::Port $dirport,
    String $exit_policy,
    Stdlib::Httpurl $apt_uri,
    String $apt_dist,
    Stdlib::Ensure::Service $service_ensure,
    Array[String] $fingerprints,
) {

    apt::package_from_component { 'thirdparty-tor':
        component => 'thirdparty/tor',
        packages  => ['tor'],
        distro    => $apt_dist,
        uri       => $apt_uri,
    }

    # status monitor for tor - https://www.atagar.com/arm/
    package { 'tor-arm':
        ensure => 'present',
    }

    $family = join($fingerprints, ',')

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
        ensure  => $service_ensure,
        require => Package['tor'],
    }
}
