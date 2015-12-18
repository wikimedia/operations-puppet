# sets up a Tor relay
class tor (
    $address,
    $nickname,
    $contact,
    $controlpassword,
    $controlport = '9051',
    $orport = '443', # use 9001 if in use
    $dirport = '80', # use 9030 if in use
    $exit_policy = 'reject *:*',
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
}
