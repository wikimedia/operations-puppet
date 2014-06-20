# sets up a Tor relay
class tor (
    $tor_address,
    $tor_nickname,
    $tor_contact,
    $tor_controlport = '9051',
    $tor_orport = '9001',
    $tor_dirport = '9030',
    ) {

    package { 'tor':
        ensure => 'present',
    }

    file { '/etc/tor/torrc':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tor/torrc.erb'),
    }

    service { 'tor':
        ensure => 'running',
    }

}
